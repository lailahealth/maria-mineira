module Chat
  class ConversationsController < ApplicationController
    def show
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
  end
end
