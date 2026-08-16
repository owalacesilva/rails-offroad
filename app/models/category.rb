class Category < ApplicationRecord
  has_many :ads, dependent: :restrict_with_error

  # case_sensitive: false acompanha o banco. A collation padrão do MySQL
  # (utf8mb4_0900_ai_ci) ignora caixa, então o índice único já trataria
  # "veiculos-4x4" e "Veiculos-4X4" como a mesma slug; sem isto o modelo
  # prometeria uma distinção que o banco não faz.
  validates :slug, presence: true, uniqueness: { case_sensitive: false }
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
