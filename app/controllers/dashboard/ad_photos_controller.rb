module Dashboard
  # Recebe uma foto por requisição, enviada pelo Dropzone do formulário de
  # anúncio, e devolve o signed_id do blob.
  #
  # A foto só é ligada a um AdImage quando o formulário inteiro é enviado — até
  # lá o blob fica sem dono, e é a tarefa `active_storage:purge_unattached` que
  # recolhe o que ficou de formulário abandonado.
  class AdPhotosController < BaseController
    include PhotoUpload

    def create
      upload = params[:file]
      problem = photo_rejection(upload)

      return render json: { error: problem }, status: :unprocessable_content if problem

      blob = store_photo(upload)
      # A URL é de proxy, como em AdImage#url: o endpoint do MinIO só existe
      # dentro da rede do Compose, e o navegador precisa de um endereço do Rails.
      render json: { signed_id: blob.signed_id, url: rails_storage_proxy_path(blob) }, status: :created
    end
  end
end
