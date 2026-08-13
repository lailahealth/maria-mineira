class CreateAdminSessions < ActiveRecord::Migration[8.1]
  def change
    create_table :admin_sessions do |t|
      t.references :admin_user, null: false, foreign_key: { to_table: :admin_users }
      t.string :ip_address
      t.string :user_agent

      t.timestamps
    end
  end
end
