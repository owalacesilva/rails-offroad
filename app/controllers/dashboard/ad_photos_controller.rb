module Dashboard
  # Recebe uma foto por requisição, enviada pelo Dropzone do formulário de
  # anúncio, e devolve o signed_id do blob.
  #
  # A foto só é ligada a um AdImage quando o formulário inteiro é enviado — até
  # lá o blob fica sem dono, e é a tarefa `active_storage:purge_unattached` que
  # recolhe o que ficou de formulário abandonado.
  class AdPhotosController < BaseController
    MAX_WIDTH = 1024
    MAX_HEIGHT = 576

    MAX_BYTES = 5.megabytes

    # WebP entra porque o Dropzone redimensiona no navegador e pode reescrever
    # nesse formato; GIF e SVG ficam de fora de propósito — um é animação e o
    # outro é documento com script dentro.
    CONTENT_TYPES = %w[image/jpeg image/png image/webp].freeze

    def create
      upload = params[:file]
      problem = rejection(upload)

      return render json: { error: problem }, status: :unprocessable_content if problem

      blob = store(upload)
      # A URL é de proxy, como em AdImage#url: o endpoint do MinIO só existe
      # dentro da rede do Compose, e o navegador precisa de um endereço do Rails.
      render json: { signed_id: blob.signed_id, url: rails_storage_proxy_path(blob) }, status: :created
    end

    private
      def store(upload)
        ActiveStorage::Blob.create_and_upload!(
          io: upload.tempfile,
          filename: upload.original_filename,
          content_type: upload.content_type
        )
      end

      # Devolve a mensagem do problema, ou nil quando está tudo certo.
      #
      # O Dropzone já reduz a imagem antes de enviar, mas nada que vem do
      # navegador é garantia: quem impõe formato, peso e dimensão é este método.
      def rejection(upload)
        return t("dashboard.ad_photos.errors.missing") if upload.blank?
        return t("dashboard.ad_photos.errors.type") unless CONTENT_TYPES.include?(upload.content_type)
        return t("dashboard.ad_photos.errors.size", max: MAX_BYTES / 1.megabyte) if upload.size > MAX_BYTES

        oversized(upload)
      end

      def oversized(upload)
        width, height = dimensions(upload)

        return t("dashboard.ad_photos.errors.unreadable") unless width
        return if width <= MAX_WIDTH && height <= MAX_HEIGHT

        t("dashboard.ad_photos.errors.dimensions", width: MAX_WIDTH, height: MAX_HEIGHT)
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
end
