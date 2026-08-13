# Expurga conversas de chat inativas há mais de Chat::Conversation::INACTIVITY_TIMEOUT
# (seção 14 do parecer técnico: texto livre não é armazenado integralmente por
# padrão). Destruir a conversa apaga as mensagens em cascata (dependent: :destroy);
# os Journey::Event/ChatTurn já gerados a partir dela não são tocados — são o dado
# estruturado que sobrevive, não o texto. Agendado em config/recurring.yml.
class PurgeStaleChatMessagesJob < ApplicationJob
  queue_as :default

  def perform
    Chat::Conversation.where("updated_at < ?", Chat::Conversation::INACTIVITY_TIMEOUT.ago).find_each(&:destroy)
  end
end
