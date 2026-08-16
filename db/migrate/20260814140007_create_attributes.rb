# Registro das especificações técnicas possíveis. Substitui o SPECIFICATION_ORDER
# em constante: agora o vocabulário é dado, não código.
class CreateAttributes < ActiveRecord::Migration[8.1]
  DATA_TYPES = %w[STRING INT DECIMAL].freeze

  def change
    create_table :attributes, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.string :name, null: false
      t.string :data_type, null: false, default: "STRING"
      t.boolean :is_required, null: false, default: false
      # jsonb não preservava ordem e a ordem vinha de constante; agora é coluna.
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
