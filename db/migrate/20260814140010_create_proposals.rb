class CreateProposals < ActiveRecord::Migration[8.1]
  def change
    create_table :proposals do |t|
      t.references :ad, null: false, foreign_key: true
      # Nulo de propósito: proposta anônima continua permitida. Preenchido quando
      # quem envia está autenticado.
      t.references :user, null: true, foreign_key: true

      t.string :name, null: false
      t.string :email, null: false
      t.string :phone
      # Centavos em INT, pelo mesmo motivo de ads.price_cents.
      t.integer :offered_value_cents, null: false
      t.text :message

      t.timestamps
    end

    add_index :proposals, :created_at

    add_check_constraint :proposals, "offered_value_cents > 0", name: "proposals_offered_value_positive"
  end
end
