# Quais especificações cada categoria pede.
#
# Antes o vocabulário era global e `attributes.is_required` dizia, para o portal
# inteiro, o que era obrigatório — o que nunca fechou: 4x4 tem motor e portas,
# peça tem material e garantia. Agora o conjunto é por categoria, e estar ligado
# a ela já significa "obrigatório para ela": o formulário pede todos.
class CreateAttributeCategories < ActiveRecord::Migration[8.1]
  def change
    create_table :attribute_categories do |t|
      t.references :category, null: false, foreign_key: true
      # A coluna acompanha o nome usado em technical_spec_values: a tabela do
      # outro lado se chama `attributes`, não `spec_attributes`.
      t.bigint :attribute_id, null: false

      t.timestamps
    end

    add_foreign_key :attribute_categories, :attributes, column: :attribute_id
    add_index :attribute_categories, :attribute_id
    # Um atributo entra uma vez por categoria.
    add_index :attribute_categories, %i[category_id attribute_id], unique: true
  end
end
