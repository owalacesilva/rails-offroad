class AddAdsCountToUsers < ActiveRecord::Migration[8.1]
  def up
    # Contador mantido pelo Rails (counter_cache em Ad). Sem ele, filtrar e
    # ordenar a lista de anunciantes por quantidade de anúncios exigiria um
    # GROUP BY que a paginação por offset teria de contar duas vezes.
    add_column :users, :ads_count, :integer, null: false, default: 0
    add_index :users, :ads_count

    # SQL direto e não o modelo: migração que carrega classe da aplicação quebra
    # quando o modelo muda depois.
    execute <<~SQL.squish
      UPDATE users SET ads_count = (SELECT COUNT(*) FROM ads WHERE ads.user_id = users.id)
    SQL
  end

  def down
    remove_column :users, :ads_count
  end
end
