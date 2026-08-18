# Identidade separada da de usuário: quem modera não anuncia, e a concern de
# autenticação do anunciante fica intocada.
class CreateAdmins < ActiveRecord::Migration[8.1]
  def change
    create_table :admins do |t|
      t.string :name, null: false
      t.string :email, null: false
      t.string :password_hash, null: false

      t.timestamps
    end

    add_index :admins, :email, unique: true
  end
end
