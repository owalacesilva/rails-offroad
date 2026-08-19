require "rails_helper"

RSpec.describe WatermarkAdPhotosJob, type: :job do
  let(:ad) { create(:ad, image_count: 0, status: :pending) }

  def attach(blob, sort_order:)
    image = build(:ad_image, ad: ad, file_url: nil, sort_order: sort_order)
    image.file.attach(blob)
    image.save!

    image
  end

  it "carimba todas as fotos do anúncio" do
    images = Array.new(3) { |index| attach(photo_blob, sort_order: index) }

    described_class.perform_now(ad)

    expect(images.map { |image| image.reload.watermarked_at }).to all(be_present)
  end

  # Uma foto que a libvips não consegue reler não pode levar as outras junto —
  # nem derrubar o job em retentativa infinita.
  describe "quando uma foto falha" do
    let(:broken) do
      ActiveStorage::Blob.create_and_upload!(
        io: StringIO.new("isto não é uma imagem"), filename: "quebrada.png", content_type: "image/png"
      )
    end

    it "carimba as outras assim mesmo" do
      attach(broken, sort_order: 0)
      good = attach(photo_blob, sort_order: 1)

      described_class.perform_now(ad)

      expect(good.reload.watermarked_at).to be_present
    end

    it "não estoura" do
      attach(broken, sort_order: 0)

      expect { described_class.perform_now(ad) }.not_to raise_error
    end

    it "deixa a foto que falhou sem marca" do
      image = attach(broken, sort_order: 0)

      described_class.perform_now(ad)

      expect(image.reload.watermarked_at).to be_nil
    end
  end

  # O seed aponta as fotos para /seed-images, sem blob nenhum.
  it "atravessa o anúncio cujas fotos são só URL" do
    seeded = create(:ad)

    expect { described_class.perform_now(seeded) }.not_to raise_error
  end

  # Anúncio apagado entre o enfileiramento e a execução não é erro: não há o
  # que carimbar. O round-trip pelo serialize é o que faz o job reencontrar o
  # anúncio pelo id, como aconteceria na fila de verdade.
  it "descarta a si mesmo quando o anúncio já não existe" do
    gone = create(:ad, image_count: 0, status: :pending)
    enqueued = described_class.new(gone).serialize
    gone.destroy

    expect { ActiveJob::Base.execute(enqueued) }.not_to raise_error
  end
end
