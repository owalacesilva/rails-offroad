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
  # Foto bloqueada pela moderação some do portal inteiro; a gestão continua
  # vendo para poder desbloquear.
  scope :visible, -> { where(blocked_at: nil) }
  scope :blocked, -> { where.not(blocked_at: nil) }

  # De onde a foto é exibida.
  def url
    return file_url unless file.attached?

    attachment_path(file)
  end

  def blocked?
    blocked_at.present?
  end

  private
    # Uma das duas origens tem que existir; qual delas é indiferente.
    def source_present
      return if file_url.present? || file.attached?

      errors.add(:base, :missing_file)
    end
end
