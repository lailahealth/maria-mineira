module Chat
  # Texto livre da conversa — criptografado em repouso e com vida curta por padrão
  # (seção 14 do parecer técnico). O que sobrevive de fato para análise agregada são
  # os Journey::Event/ChatTurn gerados a partir de cada mensagem, não o texto aqui.
  class Message < ApplicationRecord
    self.table_name = "chat_messages"

    encrypts :body

    enum :role, { user: 0, assistant: 1, system_card: 2 }
    enum :card_type, {
      location_prompt: 0,
      facility_results: 1,
      municipio_sem_cobertura: 2,
      emergencia: 3
    }, prefix: true, allow_nil: true

    belongs_to :conversation, class_name: "Chat::Conversation", foreign_key: :chat_conversation_id

    validates :role, presence: true
  end
end
