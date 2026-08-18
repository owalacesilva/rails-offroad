# Post do blog do portal. Conteúdo editorial da equipe, como os eventos: não
# pertence a anunciante nenhum e não passa por fila de aprovação.
#
# Não há coluna de status. `published_at` diz tudo: nulo é rascunho, no futuro é
# publicação agendada, no passado é o que o público vê.
class Post < ApplicationRecord
  # Quantos caracteres do corpo viram resumo quando não há chamada própria.
  SUMMARY_LENGTH = 180

  belongs_to :admin

  # Capa enviada pela gestão. A coluna cover_url segue valendo como origem
  # alternativa, e #cover escolhe entre as duas.
  has_one_attached :cover_image

  before_validation :assign_slug

  validates :title, presence: true
  validates :slug, presence: true, uniqueness: { case_sensitive: false }
  validates :body, presence: true
  validates :cover_url, format: { with: HTTP_URL }, allow_blank: true

  # A ordem é a da leitura: o mais recente primeiro.
  scope :published, -> { where(published_at: ..Time.current).order(published_at: :desc) }
  # Já tem data marcada, mas ela ainda não chegou.
  scope :scheduled, -> { where(published_at: Time.current..).order(:published_at) }
  scope :drafts, -> { where(published_at: nil).order(updated_at: :desc) }

  # Mesmo prefixo fixo do formulário de evento (ver Event#url=).
  def cover_url=(value)
    super(self.class.with_http_scheme(value))
  end

  # O corpo é texto rico, limpo na entrada: o banco só guarda o que está dentro
  # de RICH_TEXT_TAGS (ver ApplicationRecord).
  def body=(value)
    super(self.class.sanitize_rich_text(value))
  end

  # A URL usa a slug, não o id.
  def to_param
    slug
  end

  def published?
    published_at.present? && published_at <= Time.current
  end

  def scheduled?
    published_at.present? && published_at > Time.current
  end

  # Resumo dos cards. Sem chamada própria, corta o corpo já sem as tags — o
  # texto do card é texto, não HTML.
  def summary(length: SUMMARY_LENGTH)
    return excerpt if excerpt.present?

    ActionView::Base.full_sanitizer.sanitize(body.to_s).squish.truncate(length)
  end

  # Segunda barreira, como em Event#cover_url: vale também para linha gravada
  # por fora do modelo.
  def cover
    return attachment_path(cover_image) if cover_image.attached?

    http_url(cover_url)
  end

  private
    # Gerada uma vez e nunca mais: mudar o título de um post publicado não pode
    # quebrar o link que ele já espalhou.
    def assign_slug
      return if slug.present? || title.blank?

      self.slug = self.class.unique_slug(title.parameterize.presence || "post")
    end
end
