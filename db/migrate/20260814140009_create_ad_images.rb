# Substitui o Active Storage: URL e ordem explícitas, sem blob nem variante.
class CreateAdImages < ActiveRecord::Migration[8.1]
  def change
    create_table :ad_images, id: :string, limit: 36 do |t|
      t.references :ad, type: :string, limit: 36, null: false, foreign_key: true
      t.string :file_url, null: false
      t.integer :sort_order, null: false, default: 0

      t.timestamps
    end

    add_index :ad_images, %i[ad_id sort_order]
  end
end
