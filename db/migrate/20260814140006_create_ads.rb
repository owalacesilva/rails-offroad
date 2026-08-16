class CreateAds < ActiveRecord::Migration[8.1]
  STATUSES = %w[draft pending approved rejected].freeze

  def change
    create_table :ads, id: :string, limit: 36 do |t|
      t.references :user, type: :string, limit: 36, null: false, foreign_key: true
      t.references :category, type: :string, limit: 36, null: false, foreign_key: true
      # Quem avaliou. Nulo enquanto o anúncio não passou por moderação.
      t.references :admin, type: :string, limit: 36, null: true, foreign_key: true

      t.string :title, null: false
      t.text :description
      # DECIMAL em reais, não centavos inteiros.
      t.decimal :price, precision: 12, scale: 2, null: false
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

    add_index :ads, :price
    add_index :ads, :published_at
    add_index :ads, :status
    add_index :ads, :year
    add_index :ads, %i[state city]

    add_check_constraint :ads, "price > 0", name: "ads_price_positive"
    add_check_constraint :ads,
                         "status IN (#{STATUSES.map { |s| "'#{s}'" }.join(',')})",
                         name: "ads_status_valid"
  end
end
