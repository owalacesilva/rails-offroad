# Agenda do off-road na home: trilhas, encontros e feiras. Conteúdo do portal,
# não de um anunciante — por isso não tem user_id nem passa pela moderação.
class Event < ApplicationRecord
  # Endereço externo aceito nos dois campos de URL. Só http(s): um
  # "javascript:..." ou um "data:..." gravado direto no banco viraria link
  # clicável — ou imagem — na home.
  HTTP_URL = %r{\Ahttps?://\S+\z}i

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

  # "Próximos" inclui o que já começou e ainda não acabou: um encontro de três
  # dias continua sendo notícia no segundo dia. COALESCE resolve o evento de um
  # dia só, em que ends_on é nulo e quem manda é a data de início.
  scope :upcoming, lambda {
    where("COALESCE(events.ends_on, events.starts_on) >= ?", Date.current)
      .order(:starts_on, :title)
  }

  # Já passou. Ordem invertida: na gestão, o que acabou de terminar é o que
  # interessa primeiro.
  scope :past, lambda {
    where("COALESCE(events.ends_on, events.starts_on) < ?", Date.current)
      .order(starts_on: :desc, title: :asc)
  }

  def single_day?
    ends_on.blank? || ends_on == starts_on
  end

  # Segunda barreira, para o card não depender de a linha ter passado pela
  # validação do modelo: vale também para o que foi gravado por SQL direto.
  def external_url
    self.class.http_url(url)
  end

  def cover_url
    self.class.http_url(image_url)
  end

  def self.http_url(value)
    value if value.to_s.match?(%r{\Ahttps?://}i)
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
