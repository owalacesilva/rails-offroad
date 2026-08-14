class CreateProposals < ActiveRecord::Migration[8.1]
  def change
    create_table :proposals do |t|
      t.references :listing, null: false, foreign_key: true
      t.string :name, null: false
      t.string :email, null: false
      t.string :phone
      t.integer :amount_cents, null: false
      t.text :message

      t.timestamps
    end

    add_index :proposals, :created_at

    add_check_constraint :proposals, "amount_cents > 0", name: "proposals_amount_cents_positive"
  end
end
