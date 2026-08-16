class Ad < ApplicationRecord
  # `new` colidiria com Ad.new, daí new_arrival.
  BADGES = { prepared: 0, featured: 1, new_arrival: 2 }.freeze

  # Fluxo de moderação: nasce em pending, um admin aprova ou rejeita.
  STATUSES = { draft: "draft", pending: "pending", approved: "approved", rejected: "rejected" }.freeze

  # A cardinalidade "has (3 to 10)" do diagrama, agora de fato validada.
  IMAGE_COUNT = (3..10).freeze

  RELATED_LIMIT = 4

  belongs_to :user
  belongs_to :category
  # Quem avaliou. Nulo enquanto ninguém moderou.
  belongs_to :admin, optional: true

  has_many :proposals, dependent: :destroy
  has_many :ad_images, -> { ordered }, dependent: :destroy, inverse_of: :ad
  has_many :technical_spec_values, dependent: :destroy, inverse_of: :ad
  has_many :spec_attributes, through: :technical_spec_values, source: :spec_attribute

  enum :badge, BADGES, prefix: true
  enum :status, STATUSES

  validates :title, presence: true
  validates :city, presence: true
  validates :state, presence: true, length: { is: 2 }
  validates :price, numericality: { greater_than: 0 }
  validates :year,
            numericality: {
              only_integer: true,
              greater_than: 1900,
              less_than_or_equal_to: ->(_ad) { Date.current.year + 1 }
            },
            allow_nil: true
  # Só cobra fotos de quem já está no ar: rascunho pode estar incompleto.
  validate :image_count_within_bounds, if: :approved?

  # Só anúncio aprovado aparece publicamente. É o ponto do fluxo de moderação.
  scope :published, -> { where(status: STATUSES[:approved]) }
  scope :recent, -> { order(published_at: :desc) }
  # Subconsulta em vez de joins: evita conflito com o includes(:category) da listagem.
  scope :by_category, ->(slug) { where(category: Category.where(slug: slug)) }
  scope :by_state, ->(state) { where(state: state) }
  scope :by_city, ->(city) { where(city: city) }

  # Antes vinha de um hash jsonb ordenado por constante; agora a ordem é a
  # coluna `position` do atributo.
  def ordered_specifications
    technical_spec_values.includes(:spec_attribute).sort_by(&:position).map(&:to_pair)
  end

  def cover_image
    ad_images.first
  end

  # Aprova e publica em um passo: registrar quem avaliou é parte da aprovação.
  # Devolve false em vez de estourar — anúncio sem as 3 fotos não passa, e a
  # controller precisa mostrar isso na fila de moderação.
  def approve(admin)
    now = Time.current

    update(status: :approved, admin: admin, reviewed_at: now, published_at: published_at || now)
  end

  def reject(admin)
    update(status: :rejected, admin: admin, reviewed_at: Time.current)
  end

  # Mesma categoria, exceto o próprio anúncio. Deliberadamente simples: não
  # pondera estado nem faixa de preço.
  def related(limit: RELATED_LIMIT)
    self.class.published
        .includes(:category, :ad_images)
        .where(category_id: category_id)
        .where.not(id: id)
        .recent
        .limit(limit)
  end

  private
    def image_count_within_bounds
      return if IMAGE_COUNT.cover?(ad_images.size)

      errors.add(:ad_images, :invalid_count, min: IMAGE_COUNT.min, max: IMAGE_COUNT.max)
    end
end
