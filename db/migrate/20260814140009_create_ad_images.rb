# Fotos do anúncio. A ordem é coluna explícita, que é o motivo de a tabela
# existir em vez de um has_many_attached solto no Ad.
class CreateAdImages < ActiveRecord::Migration[8.1]
  def change
    create_table :ad_images do |t|
      t.references :ad, null: false, foreign_key: true
      # Nula quando a foto é um blob do Active Storage, enviado pelo formulário;
      # preenchida quando é uma URL pronta, que é como o seed aponta para
      # /seed-images. Ver AdImage#url.
      t.string :file_url
      t.integer :sort_order, null: false, default: 0

      t.timestamps
    end

    add_index :ad_images, %i[ad_id sort_order]
  end
end
