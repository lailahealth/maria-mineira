module Chat
  class ConversationsController < ApplicationController
    def show
      record_chat_opened
      @conversation = current_chat_conversation
      Chat::TurnHandler.new(conversation: @conversation, journey_session: current_journey_session).start!
      @conversation.reload
      @messages = @conversation.messages.order(:created_at)
    end

    # "Encerrar conversa": apaga a conversa atual (e suas mensagens, em cascata)
    # e volta para o estado inicial. Só o texto é apagado — os Journey::Event já
    # gerados a partir dela permanecem, são o dado estruturado que a Maria Mineira
    # retém por padrão (seção 14 do parecer técnico).
    def destroy
      current_chat_conversation.destroy
      redirect_to chat_path
    end

    private

    # Um evento por sessão, mesmo com várias visitas/recarregamentos de /converse —
    # não é "mandou mensagem" (Journey::Event.chatbot/motivo), só marca que o chat
    # foi aberto, para o painel distinguir sessão -> abriu o chat -> escreveram.
    def record_chat_opened
      return if Journey::Event.chat_aberto.exists?(journey_session_id: current_journey_session.id)

      Journey::EventRecorder.record(session: current_journey_session, event_type: :chat_aberto)
    end
  end
end
