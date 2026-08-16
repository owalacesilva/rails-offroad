class CreateAdminSessions < ActiveRecord::Migration[8.1]
  def change
    create_table :admin_sessions, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :admin, type: :uuid, null: false, foreign_key: true
      t.string :ip_address
      t.string :user_agent

      t.timestamps
    end
  end
end
