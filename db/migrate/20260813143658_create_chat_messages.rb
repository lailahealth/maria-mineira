class CreateChatMessages < ActiveRecord::Migration[8.1]
  def change
    create_table :chat_messages do |t|
      t.references :chat_conversation, null: false, foreign_key: true
      t.integer :role, null: false
      t.integer :card_type
      # Texto livre — criptografado em aplicação (Active Record Encryption, ver model)
      # e sujeito a expurgo periódico (seção 14 do parecer técnico).
      t.text :body

      t.timestamps
    end
  end
end
