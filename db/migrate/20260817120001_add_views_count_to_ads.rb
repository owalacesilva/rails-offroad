class AddViewsCountToAds < ActiveRecord::Migration[8.1]
  def change
    # Contador denormalizado em vez de uma tabela de visitas: a home só precisa
    # ordenar os doze mais vistos, e uma linha por visualização custaria um
    # COUNT sobre o acervo inteiro a cada carregamento.
    add_column :ads, :views_count, :integer, null: false, default: 0

    # A home ordena por este contador dentro dos publicados.
    add_index :ads, :views_count

    add_check_constraint :ads, "views_count >= 0", name: "ads_views_count_not_negative"
  end
end
