module Journey
  # Assunto que emergiu na conversa livre com a Maria Mineira (tag_chat/subtag_chat),
  # sem persistir o texto em si — ver Chat::Message para a política de retenção do texto.
  class ChatTurn < AnalyticsRecord
    self.table_name = "journey_chat_turns"

    belongs_to :session, class_name: "Journey::Session", foreign_key: :journey_session_id
  end
end
