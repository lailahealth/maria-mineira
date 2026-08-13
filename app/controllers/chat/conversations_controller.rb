module Chat
  class ConversationsController < ApplicationController
    def show
      @conversation = current_chat_conversation
      Chat::TurnHandler.new(conversation: @conversation, journey_session: current_journey_session).start!
      @conversation.reload
      @messages = @conversation.messages.order(:created_at)
    end
  end
end
