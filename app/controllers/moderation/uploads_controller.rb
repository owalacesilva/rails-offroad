module Moderation
  # Capa de evento e de post, uma por requisição. Mesma validação do upload de
  # foto de anúncio (ver PhotoUpload); o que muda é a sessão exigida.
  #
  # O blob só ganha dono quando o formulário é enviado; o que sobra de
  # formulário abandonado é recolhido por `active_storage:purge_unattached`.
  class UploadsController < BaseController
    include PhotoUpload

    def create
      upload = params[:file]
      problem = photo_rejection(upload)

      return render json: { error: problem }, status: :unprocessable_content if problem

      blob = store_photo(upload)

      render json: { signed_id: blob.signed_id, url: rails_storage_proxy_path(blob) }, status: :created
    end
  end
end
