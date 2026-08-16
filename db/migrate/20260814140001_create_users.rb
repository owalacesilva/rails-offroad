class CreateUsers < ActiveRecord::Migration[8.1]
  STATES = %w[
    AC AL AP AM BA CE DF ES GO MA MT MS MG PA PB PR PE PI RJ RN RS RO RR SC SP SE TO
  ].freeze

  def change
    create_table :users, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.string :name, null: false
      t.string :email, null: false
      t.string :password_hash, null: false
      t.string :phone, null: false
      t.string :city, null: false
      t.string :state, limit: 2, null: false
      t.date :member_since, null: false

      t.timestamps
    end

    add_index :users, :email, unique: true

    # A lista de UFs agora vive no banco, não só no modelo: escrita direta por SQL
    # também passa a ser barrada.
    add_check_constraint :users,
                         "state IN (#{STATES.map { |uf| "'#{uf}'" }.join(',')})",
                         name: "users_state_valid"
  end
end
