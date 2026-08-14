class Listing < ApplicationRecord
  # `new` colidiria com Listing.new, daí new_arrival.
  BADGES = { prepared: 0, featured: 1, new_arrival: 2 }.freeze

  RELATED_LIMIT = 4

  # jsonb não preserva a ordem das chaves, então a ordem de exibição é definida
  # aqui. Chave fora da lista vai para o fim.
  SPECIFICATION_ORDER = %w[
    condition mileage_km engine power transmission traction fuel doors color
    brand material warranty
  ].freeze

  belongs_to :category
  belongs_to :advertiser

  has_many :proposals, dependent: :destroy
  has_many_attached :photos

  enum :badge, BADGES, prefix: true

  validates :title, presence: true
  validates :city, presence: true
  validates :published_at, presence: true
  validates :state, presence: true, length: { is: 2 }
  validates :price_cents, numericality: { only_integer: true, greater_than: 0 }
  validates :year,
            numericality: {
              only_integer: true,
              greater_than: 1900,
              less_than_or_equal_to: ->(_listing) { Date.current.year + 1 }
            },
            allow_nil: true

  scope :recent, -> { order(published_at: :desc) }
  # Subconsulta em vez de joins: evita conflito com o includes(:category) da listagem.
  scope :by_category, ->(slug) { where(category: Category.where(slug: slug)) }
  scope :by_state, ->(state) { where(state: state) }
  scope :by_city, ->(city) { where(city: city) }

  def price
    BigDecimal(price_cents) / 100
  end

  def ordered_specifications
    specifications.sort_by { |key, _value| SPECIFICATION_ORDER.index(key) || SPECIFICATION_ORDER.size }
  end

  # Mesma categoria, exceto o próprio anúncio. Deliberadamente simples: não
  # pondera estado nem faixa de preço.
  def related(limit: RELATED_LIMIT)
    self.class.includes(:category)
        .where(category_id: category_id)
        .where.not(id: id)
        .recent
        .limit(limit)
  end
end
