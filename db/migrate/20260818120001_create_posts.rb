class CreatePosts < ActiveRecord::Migration[8.1]
  def change
    # Blog do portal: conteúdo editorial, escrito pela equipe. Não pertence a
    # anunciante nenhum e não passa por fila de aprovação, como os eventos.
    create_table :posts do |t|
      # Quem escreveu. A identidade é a de moderador, não a de anunciante.
      t.references :admin, null: false, foreign_key: true

      t.string :title, null: false
      # Derivada do título e usada na URL no lugar do id (ver Post#to_param).
      t.string :slug, null: false
      # Chamada curta dos cards. Vazia, a listagem resume o corpo.
      t.text :excerpt
      # HTML das mesmas tags que o editor da descrição de anúncio produz,
      # limpo na entrada (ver ApplicationRecord.sanitize_rich_text).
      t.text :body, null: false
      t.string :cover_url

      # Nulo é rascunho; data no futuro é publicação agendada. É o que separa o
      # que o público vê do que só a equipe enxerga — sem coluna de status.
      t.datetime :published_at

      t.timestamps
    end

    add_index :posts, :slug, unique: true
    # A listagem pública ordena por aqui, filtrando pelo que já saiu.
    add_index :posts, :published_at
  end
end
