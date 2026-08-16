# Lado "Value" do EAV. Chave primária composta: um anúncio não repete atributo.
class TechnicalSpecValue < ApplicationRecord
  self.primary_key = %i[ad_id attribute_id]

  belongs_to :ad
  belongs_to :spec_attribute, class_name: "SpecAttribute", foreign_key: :attribute_id,
                              inverse_of: :technical_spec_values

  # A ordem de exibição é do atributo, não da linha de valor.
  delegate :position, to: :spec_attribute

  validates :value, presence: true

  # Par [nome, valor tipado] que a view do anúncio consome.
  def to_pair
    [ spec_attribute.name, typed_value ]
  end

  # Guardado sempre como texto; o data_type do atributo diz como ler de volta.
  def typed_value
    case spec_attribute.data_type
    when "INT" then Integer(value, exception: false) || value
    when "DECIMAL" then BigDecimal(value, exception: false) || value
    else value
    end
  end
end
