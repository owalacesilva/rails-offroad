require "rails_helper"

RSpec.describe "Bloqueio de foto de anúncio", type: :request do
  let(:admin) { create(:admin) }
  # Quatro fotos: bloquear uma ainda deixa o anúncio dentro do mínimo.
  let(:ad) { create(:ad, image_count: 4) }

  before { sign_in_admin(admin) }

  describe "PATCH bloquear" do
    it "tira a foto do ar" do
      image = ad.ad_images.first

      patch admin_ad_image_path(ad, image)

      expect(image.reload).to be_blocked
    end

    it "some da listagem pública" do
      image = ad.ad_images.first

      patch admin_ad_image_path(ad, image)

      expect(ad.reload.visible_images).not_to include(image)
    end

    it "mantém o anúncio no ar quando ainda sobra o mínimo" do
      patch admin_ad_image_path(ad, ad.ad_images.first)

      expect(ad.reload).to be_approved
    end

    it "guarda o recado do moderador" do
      patch admin_ad_image_path(ad, ad.ad_images.first, note: "Foto de catálogo.")

      expect(ad.reload.moderation_note).to eq("Foto de catálogo.")
    end

    # O ponto do item: aprovado com menos que o mínimo é um estado que a
    # validação não aceita, então o anúncio volta para a fila.
    context "quando sobra menos que o mínimo" do
      let(:ad) { create(:ad, image_count: Ad::IMAGE_COUNT.min) }

      it "devolve o anúncio para a fila" do
        patch admin_ad_image_path(ad, ad.ad_images.first)

        expect(ad.reload).to be_pending
      end

      it "sai do portal" do
        patch admin_ad_image_path(ad, ad.ad_images.first)

        expect(Ad.published).not_to include(ad)
      end
    end

    # Rascunho e rejeitado já não aparecem: promovê-los a pendente desfaria o
    # que a moderação tinha decidido.
    context "quando o anúncio não está aprovado" do
      let(:ad) { create(:ad, :rejected, image_count: 3) }

      it "não muda o status" do
        patch admin_ad_image_path(ad, ad.ad_images.first)

        expect(ad.reload).to be_rejected
      end
    end
  end

  describe "DELETE liberar" do
    it "devolve a foto ao ar" do
      image = ad.ad_images.first
      image.update!(blocked_at: Time.current)

      delete admin_ad_image_path(ad, image)

      expect(image.reload).not_to be_blocked
    end
  end

  describe "efeito no portal" do
    it "a foto bloqueada não aparece na página do anúncio" do
      image = ad.ad_images.first
      patch admin_ad_image_path(ad, image)

      get ad_path(ad)

      expect(response.body).not_to include(image.url)
    end

    it "a capa passa a ser a próxima foto visível" do
      first = ad.ad_images.first
      patch admin_ad_image_path(ad, first)

      expect(ad.reload.cover_image).not_to eq(first)
    end
  end

  describe "acesso" do
    it "exige sessão de moderador" do
      image = ad.ad_images.first
      delete admin_logout_path

      patch admin_ad_image_path(ad, image)

      expect(image.reload).not_to be_blocked
    end
  end
end
