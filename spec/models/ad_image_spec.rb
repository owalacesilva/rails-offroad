require "rails_helper"

RSpec.describe AdImage, type: :model do
  subject { build(:ad_image) }

  it { is_expected.to belong_to(:ad) }

  # A foto vem de um blob do Active Storage (upload) ou de uma URL pronta (seed).
  # Qualquer uma das duas serve; nenhuma das duas, não.
  describe "origem do arquivo" do
    it "aceita só a URL" do
      expect(build(:ad_image, file_url: "/seed-images/foto.png")).to be_valid
    end

    it "aceita só o arquivo enviado" do
      image = build(:ad_image, file_url: nil)
      image.file.attach(photo_blob)

      expect(image).to be_valid
    end

    it "recusa quando não há nenhuma das duas" do
      image = build(:ad_image, file_url: nil)

      expect(image).not_to be_valid
      expect(image.errors[:base]).to include(I18n.t("activerecord.errors.models.ad_image.attributes.base.missing_file"))
    end
  end

  describe "#url" do
    it "usa a URL pronta quando não há arquivo enviado" do
      expect(build(:ad_image, file_url: "/seed-images/foto.png").url).to eq("/seed-images/foto.png")
    end

    # Proxy e não URL direta do MinIO: o endpoint do bucket só existe dentro da
    # rede do Compose, e o navegador do host não o resolve.
    it "serve o arquivo enviado pela rota de proxy do Active Storage" do
      image = build(:ad_image, file_url: nil)
      image.file.attach(photo_blob)

      expect(image.url).to start_with("/rails/active_storage/blobs/proxy/")
    end
  end

  it "ordena pela coluna sort_order, que o Active Storage não tinha" do
    ad = create(:ad, image_count: 0, status: :pending)
    last = create(:ad_image, ad: ad, sort_order: 2)
    first = create(:ad_image, ad: ad, sort_order: 0)
    middle = create(:ad_image, ad: ad, sort_order: 1)

    expect(ad.ad_images.reload.to_a).to eq([ first, middle, last ])
  end

  it "recusa ordem negativa" do
    expect(build(:ad_image, sort_order: -1)).not_to be_valid
  end

  it "some junto com o anúncio" do
    ad = create(:ad)

    expect { ad.destroy }.to change(described_class, :count).by(-Ad::IMAGE_COUNT.min)
  end

  describe "#apply_watermark" do
    let(:ad) { create(:ad, image_count: 0, status: :pending) }

    # Foto como o formulário a deixa: blob anexado, sem file_url.
    def attached_image
      image = build(:ad_image, ad: ad, file_url: nil)
      image.file.attach(photo_blob)
      image.save!

      image
    end

    it "troca o blob pelo carimbado" do
      image = attached_image

      expect { image.apply_watermark }.to change { image.reload.file.blob.id }
    end

    it "registra quando carimbou" do
      image = attached_image
      image.apply_watermark

      expect(image.reload.watermarked_at).to be_present
    end

    # O blob novo entra no lugar do antigo: nome e tipo continuam sendo os da
    # foto que o anunciante enviou.
    it "mantém o nome e o tipo do arquivo" do
      image = attached_image
      image.apply_watermark

      expect(image.reload.file.blob).to have_attributes(filename: image.file.filename, content_type: "image/png")
    end

    # O ActiveJob repete a tentativa, e marca dobrada não sai mais.
    it "não carimba a mesma foto duas vezes" do
      image = attached_image
      image.apply_watermark

      expect { expect(image.apply_watermark).to be(false) }.not_to change { image.reload.file.blob.id }
    end

    # Foto do seed aponta para /seed-images: não há blob para reescrever.
    it "passa direto pela foto que só tem URL" do
      image = create(:ad_image, ad: ad)

      expect(image.apply_watermark).to be(false)
      expect(image.reload.watermarked_at).to be_nil
    end
  end

  # Foto bloqueada pela moderação some do portal, mas continua no banco: a
  # gestão precisa dela para poder liberar de volta.
  describe "bloqueio" do
    it "nasce liberada" do
      expect(build(:ad_image)).not_to be_blocked
    end

    it "visible deixa de fora a bloqueada" do
      ad = create(:ad, image_count: 4)
      blocked = ad.ad_images.first
      blocked.update!(blocked_at: Time.current)

      expect(ad.ad_images.visible).not_to include(blocked)
      expect(ad.ad_images.blocked).to eq([ blocked ])
    end
  end
end
