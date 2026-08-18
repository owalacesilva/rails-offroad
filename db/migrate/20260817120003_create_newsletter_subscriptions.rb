class CreateNewsletterSubscriptions < ActiveRecord::Migration[8.1]
  def change
    create_table :newsletter_subscriptions do |t|
      t.string :email, null: false
      # De onde veio a inscrição ("home"). Uma coluna barata que evita ter de
      # adivinhar depois qual bloco da página converte.
      t.string :source

      t.timestamps
    end

    # A collation padrão é case-insensitive, então o índice já basta para tratar
    # "Ana@x.com" e "ana@x.com" como a mesma inscrição.
    add_index :newsletter_subscriptions, :email, unique: true
  end
end
