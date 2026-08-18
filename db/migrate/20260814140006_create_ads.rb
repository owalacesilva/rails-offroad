class CreateAds < ActiveRecord::Migration[8.1]
  STATUSES = %w[draft pending approved rejected].freeze

  def change
    create_table :ads do |t|
      t.references :user, null: false, foreign_key: true
      t.references :category, null: false, foreign_key: true
      # Quem avaliou. Nulo enquanto o anúncio não passou por moderação.
      t.references :admin, null: true, foreign_key: true

      t.string :title, null: false
      # Derivada do título e usada na URL no lugar do id (ver Ad#to_param).
      t.string :slug, null: false
      t.text :description
      # Centavos em INT, não DECIMAL em reais: dinheiro inteiro não tem o que
      # arredondar, e o int de 4 bytes vai até R$ 21.474.836,47 — folga larga
      # para qualquer veículo. A conversão de e para reais fica no modelo.
      t.integer :price_cents, null: false
      t.string :status, null: false, default: "pending"
      t.integer :year
      t.integer :badge
      t.string :city, null: false
      t.string :state, limit: 2, null: false
      # Só ganha data quando a moderação aprova.
      t.datetime :published_at
      t.datetime :reviewed_at

      t.timestamps
    end

    add_index :ads, :slug, unique: true
    add_index :ads, :price_cents
    add_index :ads, :published_at
    add_index :ads, :status
    add_index :ads, :year
    add_index :ads, %i[state city]

    add_check_constraint :ads, "price_cents > 0", name: "ads_price_positive"
    add_check_constraint :ads,
                         "status IN (#{STATUSES.map { |s| "'#{s}'" }.join(',')})",
                         name: "ads_status_valid"
  end
end
