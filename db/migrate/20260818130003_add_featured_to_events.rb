class AddFeaturedToEvents < ActiveRecord::Migration[8.1]
  def change
    # O evento em destaque no banner da home. Só um de cada vez: quem marca um
    # desmarca o anterior (ver Event#feature!).
    add_column :events, :featured, :boolean, null: false, default: false

    add_index :events, :featured
  end
end
