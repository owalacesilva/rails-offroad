class Listing < ApplicationRecord
  # `new` colidiria com Listing.new, daí new_arrival.
  BADGES = { prepared: 0, featured: 1, new_arrival: 2 }.freeze

  belongs_to :category

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
end
