class AddDetailsToListings < ActiveRecord::Migration[8.1]
  def up
    add_column :listings, :description, :text
    # Especificações variam por categoria (4x4 tem câmbio, peça tem material),
    # então jsonb em vez de uma coluna por atributo.
    add_column :listings, :specifications, :jsonb, null: false, default: {}
    add_reference :listings, :advertiser, foreign_key: true

    backfill_advertiser

    change_column_null :listings, :advertiser_id, false
  end

  def down
    remove_reference :listings, :advertiser
    remove_column :listings, :specifications
    remove_column :listings, :description
  end

  private
    # Os anúncios semeados antes do model Advertiser precisam de um dono para a
    # coluna virar NOT NULL. Em banco novo (CI) o WHERE EXISTS não insere nada.
    def backfill_advertiser
      execute <<~SQL.squish
        INSERT INTO advertisers (name, email, phone, city, state, member_since, created_at, updated_at)
        SELECT 'Anunciante a migrar', 'migrar@offroadclassificados.com.br', '5541400289220',
               'Curitiba', 'PR', CURRENT_DATE, NOW(), NOW()
        WHERE EXISTS (SELECT 1 FROM listings WHERE advertiser_id IS NULL)
      SQL

      execute <<~SQL.squish
        UPDATE listings
        SET advertiser_id = (SELECT MIN(id) FROM advertisers)
        WHERE advertiser_id IS NULL
      SQL
    end
end
