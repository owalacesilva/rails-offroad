# Liga uma especificação técnica à categoria que a pede.
#
# A existência do vínculo é a própria obrigatoriedade: o formulário de anúncio
# exige todos os atributos da categoria escolhida. Não há coluna dizendo "este é
# opcional" — atributo que não se aplica simplesmente não é ligado à categoria.
class AttributeCategory < ApplicationRecord
  belongs_to :category
  # A coluna é attribute_id porque a tabela do outro lado se chama `attributes`;
  # a constante não pode ser Attribute (colide com ActiveModel::Attribute).
  belongs_to :spec_attribute, class_name: "SpecAttribute", foreign_key: :attribute_id,
                              inverse_of: :attribute_categories

  validates :attribute_id, uniqueness: { scope: :category_id }
end
