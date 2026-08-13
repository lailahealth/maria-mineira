module Chat
  # Conduz a conversa em estágios (seção 3.2.1 do parecer técnico): motivo e localização
  # são turnos dentro do próprio chat, não telas separadas — ajuste confirmado pela liderança.
  class Conversation < ApplicationRecord
    self.table_name = "chat_conversations"

    enum :stage, {
      saudacao: 0,
      aguardando_motivo: 1,
      aguardando_localizacao: 2,
      apresentando_resultado: 3,
      livre: 4
    }, default: :saudacao

    belongs_to :municipality, class_name: "Territorial::Municipality", optional: true
    belongs_to :service_category, class_name: "Territorial::ServiceCategory", optional: true
    has_many :messages, class_name: "Chat::Message", foreign_key: :chat_conversation_id, dependent: :destroy

    validates :journey_session_id, presence: true
  end
end
