# Foto de um anúncio. A ordem é a coluna sort_order, explícita, que é o motivo
# de a tabela existir em vez de um has_many_attached solto.
#
# A foto vem de uma de duas origens: um blob do Active Storage, quando o
# anunciante subiu o arquivo pelo formulário, ou uma URL pronta em `file_url`,
# que é como o seed aponta para /seed-images. As duas convivem — #url escolhe.
class AdImage < ApplicationRecord
  belongs_to :ad

  has_one_attached :file

  validates :sort_order, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validate :source_present

  scope :ordered, -> { order(:sort_order, :created_at) }

  # De onde a foto é exibida.
  #
  # O blob sai pela rota de proxy do Active Storage, não por URL assinada direta
  # do MinIO: dentro da rede do Compose o endpoint é http://minio:9000, endereço
  # que o navegador do host não resolve. No proxy quem busca o arquivo é o Rails.
  #
  # only_path porque isto roda fora de uma requisição também (console, job): a
  # rota do Active Storage é uma direct route e, sem a dica, tenta montar a URL
  # absoluta e estoura por falta de host.
  def url
    return file_url unless file.attached?

    Rails.application.routes.url_helpers.rails_storage_proxy_path(file, only_path: true)
  end

  private
    # Uma das duas origens tem que existir; qual delas é indiferente.
    def source_present
      return if file_url.present? || file.attached?

      errors.add(:base, :missing_file)
    end
end
