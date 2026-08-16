class CreateProposals < ActiveRecord::Migration[8.1]
  def change
    create_table :proposals, id: :string, limit: 36 do |t|
      t.references :ad, type: :string, limit: 36, null: false, foreign_key: true
      # Nulo de propósito: proposta anônima continua permitida. Preenchido quando
      # quem envia está autenticado.
      t.references :user, type: :string, limit: 36, null: true, foreign_key: true

      t.string :name, null: false
      t.string :email, null: false
      t.string :phone
      t.decimal :offered_value, precision: 12, scale: 2, null: false
      t.text :message

      t.timestamps
    end

    add_index :proposals, :created_at

    add_check_constraint :proposals, "offered_value > 0", name: "proposals_offered_value_positive"
  end
end
