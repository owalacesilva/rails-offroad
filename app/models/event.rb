# Agenda do off-road na home: trilhas, encontros e feiras. Conteúdo do portal,
# não de um anunciante — por isso não tem user_id nem passa pela moderação.
class Event < ApplicationRecord
  # Capa enviada pela gestão. A coluna image_url continua valendo como origem
  # alternativa (é o que o seed usa), e #cover_url escolhe entre as duas.
  has_one_attached :cover_image
  # A lista de UFs mora em User porque foi lá que nasceu; é a mesma whitelist
  # que a check constraint de events.state repete no banco.
  validates :state, presence: true, inclusion: { in: User::BRAZILIAN_STATES }
  validates :title, presence: true
  validates :city, presence: true
  validates :starts_on, presence: true
  # O card da agenda transforma os dois em atributos de href e src.
  validates :url, format: { with: HTTP_URL }, allow_blank: true
  validates :image_url, format: { with: HTTP_URL }, allow_blank: true
  validate :ends_on_after_starts_on

  # A exclusividade fica no callback e não no feature!, porque o destaque também
  # é marcado pela caixa de seleção do formulário da gestão: os dois caminhos
  # precisam da mesma garantia de um só banner.
  after_save :unfeature_others, if: -> { featured? && saved_change_to_featured? }

  # "Próximos" inclui o que já começou e ainda não acabou: um encontro de três
  # dias continua sendo notícia no segundo dia. COALESCE resolve o evento de um
  # dia só, em que ends_on é nulo e quem manda é a data de início.
  scope :upcoming, lambda {
    where("COALESCE(events.ends_on, events.starts_on) >= ?", Date.current)
      .order(:starts_on, :title)
  }

  # Já passou. Ordem invertida: na gestão, o que acabou de terminar é o que
  # interessa primeiro.
  # O evento do banner da home. Só um de cada vez, e só enquanto não passar.
  scope :featured, -> { where(featured: true) }

  scope :past, lambda {
    where("COALESCE(events.ends_on, events.starts_on) < ?", Date.current)
      .order(starts_on: :desc, title: :asc)
  }

  # O que o banner mostra, ou nil quando não há destaque válido. Destaque de
  # evento que já passou não vira banner.
  def self.banner
    upcoming.featured.first
  end

  def single_day?
    ends_on.blank? || ends_on == starts_on
  end

  def external_url
    http_url(url)
  end

  def cover_url
    return attachment_path(cover_image) if cover_image.attached?

    http_url(image_url)
  end

  def location
    "#{city}, #{state}"
  end

  private
    def unfeature_others
      self.class.featured.where.not(id: id).update_all(featured: false)
    end

    # Espelha a check constraint events_dates_ordered: o formulário precisa da
    # mensagem, o banco precisa da garantia.
    def ends_on_after_starts_on
      return if ends_on.blank? || starts_on.blank? || ends_on >= starts_on

      errors.add(:ends_on, :before_start)
    end
end
