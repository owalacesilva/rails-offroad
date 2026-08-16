# Lado "Attribute" do EAV. A tabela se chama `attributes` (dicionário de dados),
# mas a constante não pode: `Attribute` colide com ActiveModel::Attribute.
class SpecAttribute < ApplicationRecord
  self.table_name = "attributes"

  DATA_TYPES = %w[STRING INT DECIMAL].freeze

  has_many :technical_spec_values, foreign_key: :attribute_id,
                                   inverse_of: :spec_attribute, dependent: :destroy

  validates :name, presence: true, uniqueness: true
  validates :data_type, presence: true, inclusion: { in: DATA_TYPES }
  validates :position, presence: true, numericality: { only_integer: true }

  # A ordem de exibição virou coluna: antes vinha de uma constante no modelo
  # porque jsonb não preservava a ordem das chaves.
  scope :ordered, -> { order(:position, :name) }
  scope :required, -> { where(is_required: true) }

  # O rótulo exibido continua traduzível, indexado pelo nome do atributo.
  def label
    I18n.t("ads.specifications.#{name}", default: name.to_s.humanize)
  end
end
