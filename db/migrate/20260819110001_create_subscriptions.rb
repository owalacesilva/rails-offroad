class CreateSubscriptions < ActiveRecord::Migration[8.1]
  def change
    # Uma assinatura do plano Premium, por cobrança. Tabela à parte, e não uma
    # coluna `plan` em users, porque o que interessa é o histórico: quem pagou,
    # quanto, quando e até quando vale. `users.status` já ensinou que situação
    # derivada de outra tabela envelhece melhor que flag duplicada.
    create_table :subscriptions do |t|
      t.references :user, null: false, foreign_key: true

      # O que mandamos ao PagBank e o que volta na notificação: é por ele que a
      # notificação encontra a linha, então tem índice único próprio.
      # O código que mandamos ao PagBank e que volta na notificação. É a única
      # coisa que liga os dois lados, nas duas direções — o painel do PagBank
      # também busca por ela, então não há por que guardar o CHEC_... também.
      #
      # Não se chama reference_id, que é o nome do campo *deles*: coluna string
      # terminada em _id neste projeto quer dizer chave em VARCHAR(36), o desenho
      # que spec/models/schema_spec.rb existe para não deixar voltar. O nome do
      # PagBank fica onde é dele, no corpo montado por Pagseguro::Order.
      t.string :gateway_reference, null: false

      t.string :status, null: false, default: "pending"
      # Centavos, como todo dinheiro do portal (ads.price_cents).
      t.integer :amount_cents, null: false

      t.datetime :paid_at
      # Até quando o Premium vale. É o que User#premium? lê — nulo enquanto não
      # houver pagamento confirmado.
      t.date :paid_through

      t.timestamps
    end

    add_index :subscriptions, :gateway_reference, unique: true
    # A pergunta que a aplicação faz: este anunciante tem Premium hoje?
    add_index :subscriptions, %i[user_id paid_through]

    # Mesma dobradinha de users.status e ads.status: a lista vale no modelo e no
    # banco, para um INSERT em SQL não inventar situação.
    add_check_constraint :subscriptions,
                         "status in ('pending', 'paid', 'declined', 'canceled')",
                         name: "subscriptions_status_valid"
    # Assinatura de graça não existe: o plano gratuito não gera linha nenhuma.
    add_check_constraint :subscriptions, "amount_cents > 0", name: "subscriptions_amount_positive"
  end
end
