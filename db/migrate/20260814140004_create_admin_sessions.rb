class CreateAdminSessions < ActiveRecord::Migration[8.1]
  def change
    create_table :admin_sessions, id: :string, limit: 36 do |t|
      t.references :admin, type: :string, limit: 36, null: false, foreign_key: true
      t.string :ip_address
      t.string :user_agent

      t.timestamps
    end
  end
end
