class CreateListings < ActiveRecord::Migration[8.1]
  def change
    create_table :listings do |t|
      t.string :title, null: false
      t.integer :year
      # Dinheiro em centavos: inteiro não sofre erro de arredondamento.
      t.integer :price_cents, null: false
      t.string :state, null: false, limit: 2
      t.string :city, null: false
      t.references :category, null: false, foreign_key: true
      t.integer :badge
      t.datetime :published_at, null: false

      t.timestamps
    end

    # Índices para os filtros da vitrine e para cada critério de ordenação.
    add_index :listings, [ :state, :city ]
    add_index :listings, :published_at
    add_index :listings, :price_cents
    add_index :listings, :year

    add_check_constraint :listings, "price_cents > 0", name: "listings_price_cents_positive"
  end
end
