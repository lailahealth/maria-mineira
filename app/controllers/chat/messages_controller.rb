module Chat
  class MessagesController < ApplicationController
    def create
      @conversation = current_chat_conversation
      handler = Chat::TurnHandler.new(conversation: @conversation, journey_session: current_journey_session)
      before_ids = @conversation.messages.pluck(:id)

      # "Ver mais" de um card de resultados vale em qualquer estágio: a pessoa pode
      # rolar de volta e pedir mais opções de uma busca anterior.
      if params[:more_facilities].present?
        @expanded_card = handler.more_facilities(params[:more_facilities])
      else
        dispatch_turn(handler)
      end

      @conversation.reload
      @new_messages = @conversation.messages.where.not(id: before_ids).order(:created_at)

      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to chat_path }
      end
    end

    private

    def dispatch_turn(handler)
      case @conversation.stage.to_sym
      when :aguardando_motivo
        handler.receive_motivo(params[:body])
      when :aguardando_localizacao
        if params[:cancel_location].present?
          handler.cancel_location_request
        elsif params[:lat].present? && params[:lng].present?
          handler.receive_location(lat: params[:lat], lng: params[:lng])
        else
          handler.receive_location(**Territorial::LocationResolver.resolve(params[:municipio]))
        end
      else
        if params[:want_location].present?
          handler.request_location
        else
          handler.receive_free_text(params[:body])
        end
      end
    end
  end
end
