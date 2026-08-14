class CreateCategories < ActiveRecord::Migration[8.1]
  def change
    create_table :categories do |t|
      # Nome e descrição são traduzíveis e vivem em config/locales, indexados por slug.
      t.string :slug, null: false
      t.integer :position, null: false, default: 0

      t.timestamps
    end

    add_index :categories, :slug, unique: true
    add_index :categories, :position
  end
end
