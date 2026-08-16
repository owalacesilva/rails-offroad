class CreateSessions < ActiveRecord::Migration[8.1]
  def change
    create_table :sessions, id: :string, limit: 36 do |t|
      t.references :user, type: :string, limit: 36, null: false, foreign_key: true
      t.string :ip_address
      t.string :user_agent

      t.timestamps
    end
  end
end
