class Category < ApplicationRecord
  has_many :ads, dependent: :restrict_with_error

  validates :slug, presence: true, uniqueness: true
  validates :position, presence: true, numericality: { only_integer: true }

  scope :ordered, -> { order(:position, :slug) }

  # Taxonomia fixa: o texto exibido é traduzível e vive em config/locales.
  def name
    I18n.t("categories.#{slug}.name")
  end

  def description
    I18n.t("categories.#{slug}.description")
  end

  # URLs de filtro usam o slug, não o id.
  def to_param
    slug
  end
end
