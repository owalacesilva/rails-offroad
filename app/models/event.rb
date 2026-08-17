# Agenda do off-road na home: trilhas, encontros e feiras. Conteúdo do portal,
# não de um anunciante — por isso não tem user_id nem passa pela moderação.
class Event < ApplicationRecord
  # A lista de UFs mora em User porque foi lá que nasceu; é a mesma whitelist
  # que a check constraint de events.state repete no banco.
  validates :state, presence: true, inclusion: { in: User::BRAZILIAN_STATES }
  validates :title, presence: true
  validates :city, presence: true
  validates :starts_on, presence: true
  validate :ends_on_after_starts_on

  # "Próximos" inclui o que já começou e ainda não acabou: um encontro de três
  # dias continua sendo notícia no segundo dia. COALESCE resolve o evento de um
  # dia só, em que ends_on é nulo e quem manda é a data de início.
  scope :upcoming, lambda {
    where("COALESCE(events.ends_on, events.starts_on) >= ?", Date.current)
      .order(:starts_on, :title)
  }

  # O card da agenda transforma isto num href. Sem a lista de esquemas, um
  # "javascript:..." gravado direto no banco viraria link clicável na home —
  # por isso a validação e, no card, o uso de #external_url em vez de #url.
  validates :url, format: { with: %r{\Ahttps?://\S+\z}i }, allow_blank: true

  def single_day?
    ends_on.blank? || ends_on == starts_on
  end

  # A URL só quando ela é de fato http(s). Segunda barreira, para o card não
  # depender de a linha ter passado pela validação do modelo.
  def external_url
    url if url.to_s.match?(%r{\Ahttps?://}i)
  end

  def location
    "#{city}, #{state}"
  end

  private
    # Espelha a check constraint events_dates_ordered: o formulário precisa da
    # mensagem, o banco precisa da garantia.
    def ends_on_after_starts_on
      return if ends_on.blank? || starts_on.blank? || ends_on >= starts_on

      errors.add(:ends_on, :before_start)
    end
end
