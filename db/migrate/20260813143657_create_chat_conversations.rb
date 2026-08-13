class CreateChatConversations < ActiveRecord::Migration[8.1]
  def change
    create_table :chat_conversations do |t|
      # Referencia Journey::Session, que vive no banco "analytics" — sem FK entre bancos.
      t.uuid :journey_session_id, null: false
      t.integer :stage, null: false, default: 0
      t.string :context_tag
      t.references :municipality, foreign_key: { to_table: :territorial_municipalities }
      t.references :service_category, foreign_key: { to_table: :territorial_service_categories }

      t.timestamps
    end

    add_index :chat_conversations, :journey_session_id
  end
end
