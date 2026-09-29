# Expurga conversas de chat inativas há mais de Chat::Conversation::INACTIVITY_TIMEOUT
# (seção 14 do parecer técnico: texto livre não é armazenado integralmente por
# padrão). Destruir a conversa apaga as mensagens em cascata (dependent: :destroy);
# os Journey::Event/ChatTurn já gerados a partir dela não são tocados — são o dado
# estruturado que sobrevive, não o texto. Agendado em config/recurring.yml.
class PurgeStaleChatMessagesJob < ApplicationJob
  queue_as :default

  def perform
    Chat::Conversation.where("updated_at < ?", Chat::Conversation::INACTIVITY_TIMEOUT.ago).find_each do |conversation|
      record_conversa_inacabada(conversation)
      conversation.destroy
    end
  end

  private

  # Um Journey::Event por conversa expurgada, marcando em que estágio ela parou
  # (tag = Chat::Conversation#stage) — sem distinguir aqui se foi "travou antes de
  # engajar" ou "recebeu resposta e não voltou", a granularidade fica pro painel
  # separar por tag. chat_conversations e journey_sessions vivem em bancos
  # diferentes (primary/analytics), por isso a busca explícita em vez de belongs_to.
  def record_conversa_inacabada(conversation)
    session = Journey::Session.find_by(id: conversation.journey_session_id)
    return unless session

    Journey::EventRecorder.record(session: session, event_type: :conversa_inacabada, tag: conversation.stage)
  end
end
