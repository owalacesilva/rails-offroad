# Recebe um arquivo de imagem, valida e devolve o blob do Active Storage.
#
# Compartilhado pelo upload de fotos do anúncio (área do anunciante) e pelo de
# capa de evento e post (moderação): os limites e a checagem são os mesmos, só a
# sessão exigida muda.
module PhotoUpload
  extend ActiveSupport::Concern

  MAX_WIDTH = 1024
  MAX_HEIGHT = 576

  MAX_BYTES = 5.megabytes

  # WebP entra porque o Dropzone redimensiona no navegador e pode reescrever
  # nesse formato; GIF e SVG ficam de fora de propósito — um é animação e o
  # outro é documento com script dentro.
  CONTENT_TYPES = %w[image/jpeg image/png image/webp].freeze

  private
    # Devolve a mensagem do problema, ou nil quando está tudo certo.
    #
    # O navegador já reduz a imagem antes de enviar, mas nada que vem de lá é
    # garantia: quem impõe formato, peso e dimensão é este método.
    def photo_rejection(upload)
      return t("uploads.errors.missing") if upload.blank?
      return t("uploads.errors.type") unless CONTENT_TYPES.include?(upload.content_type)
      return t("uploads.errors.size", max: MAX_BYTES / 1.megabyte) if upload.size > MAX_BYTES

      oversized(upload)
    end

    def store_photo(upload)
      ActiveStorage::Blob.create_and_upload!(
        io: upload.tempfile,
        filename: upload.original_filename,
        content_type: upload.content_type
      )
    end

    def oversized(upload)
      width, height = dimensions(upload)

      return t("uploads.errors.unreadable") unless width
      return if width <= MAX_WIDTH && height <= MAX_HEIGHT

      t("uploads.errors.dimensions", width: MAX_WIDTH, height: MAX_HEIGHT)
    end

    # access: :sequential lê só o cabeçalho, sem carregar a imagem inteira na
    # memória. Arquivo que não é imagem estoura Vips::Error e vira nil.
    def dimensions(upload)
      image = Vips::Image.new_from_file(upload.tempfile.path, access: :sequential)

      [ image.width, image.height ]
    rescue Vips::Error
      nil
    end
end
