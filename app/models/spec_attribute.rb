# Lado "Attribute" do EAV. A tabela se chama `attributes` (dicionário de dados),
# mas a constante não pode: `Attribute` colide com ActiveModel::Attribute.
class SpecAttribute < ApplicationRecord
  self.table_name = "attributes"

  DATA_TYPES = %w[STRING INT DECIMAL].freeze

  has_many :technical_spec_values, foreign_key: :attribute_id,
                                   inverse_of: :spec_attribute, dependent: :destroy

  # Em quais categorias este atributo é pedido. Não há coluna de
  # obrigatoriedade: o vínculo com a categoria é que a define.
  has_many :attribute_categories, foreign_key: :attribute_id,
                                  inverse_of: :spec_attribute, dependent: :destroy
  has_many :categories, through: :attribute_categories

  # case_sensitive: false pelo mesmo motivo de Category#slug: a collation padrão
  # do MySQL ignora caixa, e o índice único da coluna também.
  validates :name, presence: true, uniqueness: { case_sensitive: false }
  validates :data_type, presence: true, inclusion: { in: DATA_TYPES }
  validates :position, presence: true, numericality: { only_integer: true }

  # A ordem de exibição virou coluna: antes vinha de uma constante no modelo
  # porque jsonb não preservava a ordem das chaves.
  scope :ordered, -> { order(:position, :name) }

  # O rótulo exibido continua traduzível, indexado pelo nome do atributo.
  def label
    I18n.t("ads.specifications.#{name}", default: name.to_s.humanize)
  end
end
