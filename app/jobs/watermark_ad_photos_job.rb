# Carimba a marca do portal nas fotos de um anúncio recém-criado.
#
# Fora da requisição porque são até dez imagens passando pela libvips, e uma a
# uma com a falha isolada: uma foto que não abre não pode impedir o carimbo das
# outras nem derrubar o job inteiro em retentativa infinita. O que ficou sem
# carimbo fica com watermarked_at nulo e aparece no log.
class WatermarkAdPhotosJob < ApplicationJob
  queue_as :default

  # Anúncio apagado antes de o job rodar não é erro: não há o que carimbar.
  discard_on ActiveJob::DeserializationError

  def perform(ad)
    ad.ad_images.each { |image| stamp(image) }
  end

  private
    def stamp(image)
      image.apply_watermark
    rescue Vips::Error, ActiveStorage::FileNotFoundError => error
      Rails.logger.warn("Watermark failed on ad_image #{image.id}: #{error.message}")
      false
    end
end
