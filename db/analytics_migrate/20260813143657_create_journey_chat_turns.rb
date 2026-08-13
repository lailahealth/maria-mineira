class CreateJourneyChatTurns < ActiveRecord::Migration[8.1]
  def change
    create_table :journey_chat_turns do |t|
      t.references :journey_session, null: false, foreign_key: true, type: :uuid
      t.string :tag_chat
      t.string :subtag_chat

      t.datetime :created_at, null: false
    end
  end
end
