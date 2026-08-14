class CreateSessions < ActiveRecord::Migration[8.1]
  def change
    create_table :sessions do |t|
      t.references :advertiser, null: false, foreign_key: true
      # Guardados para o anunciante conseguir reconhecer e encerrar sessões.
      t.string :user_agent
      t.string :ip_address

      t.timestamps
    end
  end
end
