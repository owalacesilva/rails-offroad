# Taxonomia fixa: o texto exibido continua vindo de config/locales pela slug.
class CreateCategories < ActiveRecord::Migration[8.1]
  def change
    create_table :categories, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.string :slug, null: false
      t.integer :position, null: false, default: 0

      t.timestamps
    end

    add_index :categories, :slug, unique: true
    add_index :categories, :position
  end
end
