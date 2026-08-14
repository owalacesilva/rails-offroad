class CreateAdvertisers < ActiveRecord::Migration[8.1]
  def change
    create_table :advertisers do |t|
      t.string :name, null: false
      t.string :email, null: false
      # Só dígitos, com código do país: é o formato que o wa.me espera.
      t.string :phone, null: false
      t.string :city, null: false
      t.string :state, null: false, limit: 2
      t.date :member_since, null: false

      t.timestamps
    end

    add_index :advertisers, :email, unique: true
  end
end
