# Registro das especificações técnicas possíveis. Substitui o SPECIFICATION_ORDER
# em constante: agora o vocabulário é dado, não código.
class CreateAttributes < ActiveRecord::Migration[8.1]
  DATA_TYPES = %w[STRING INT DECIMAL].freeze

  def change
    create_table :attributes do |t|
      t.string :name, null: false
      t.string :data_type, null: false, default: "STRING"
      # Não há coluna de obrigatoriedade: quem define o que é exigido é o
      # vínculo com a categoria (attribute_categories). Atributo ligado a uma
      # categoria é obrigatório para ela — o formulário pede todos.
      # JSON não preservava ordem e a ordem vinha de constante; agora é coluna.
      t.integer :position, null: false, default: 0

      t.timestamps
    end

    add_index :attributes, :name, unique: true
    add_index :attributes, :position

    add_check_constraint :attributes,
                         "data_type IN (#{DATA_TYPES.map { |d| "'#{d}'" }.join(',')})",
                         name: "attributes_data_type_valid"
  end
end
