class CreateOauthIdentities < ActiveRecord::Migration[8.1]
  def change
    # Vínculo entre o anunciante e a conta dele no provedor. Tabela à parte, e
    # não duas colunas em users, porque a mesma pessoa pode entrar pelo Google e
    # pelo Facebook — e porque o par (provedor, uid) precisa de índice único
    # próprio.
    create_table :oauth_identities do |t|
      t.references :user, null: false, foreign_key: true
      t.string :provider, null: false
      t.string :uid, null: false

      t.timestamps
    end

    # Uma conta do provedor pertence a um anunciante só: sem isto, duas contas
    # do portal poderiam apontar para o mesmo Google e a segunda sequestraria o
    # login da primeira.
    add_index :oauth_identities, %i[provider uid], unique: true
    # E um anunciante vincula cada provedor uma vez só.
    add_index :oauth_identities, %i[user_id provider], unique: true

    # Mesma dobradinha de users.status: a lista vale no modelo e no banco, para
    # que um INSERT feito por SQL não invente um provedor.
    add_check_constraint :oauth_identities,
                         "provider in ('google', 'facebook')",
                         name: "oauth_identities_provider_valid"
  end
end
