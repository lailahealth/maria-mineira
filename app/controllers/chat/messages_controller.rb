module Chat
  class MessagesController < ApplicationController
    def create
      @conversation = current_chat_conversation
      handler = Chat::TurnHandler.new(conversation: @conversation, journey_session: current_journey_session)
      before_ids = @conversation.messages.pluck(:id)

      case @conversation.stage.to_sym
      when :aguardando_motivo
        handler.receive_motivo(params[:body])
      when :aguardando_localizacao
        if params[:lat].present? && params[:lng].present?
          handler.receive_location(lat: params[:lat], lng: params[:lng])
        else
          municipality = find_municipality(params[:municipio])
          handler.receive_location(municipality: municipality)
        end
      else
        handler.receive_free_text(params[:body])
      end

      @conversation.reload
      @new_messages = @conversation.messages.where.not(id: before_ids).order(:created_at)

      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to chat_path }
      end
    end

    private

    def find_municipality(query)
      return nil if query.blank?

      Territorial::Municipality.find_by("lower(name) = ?", query.to_s.strip.downcase) ||
        Territorial::Municipality.where("name ILIKE ?", "%#{query.to_s.strip}%").first
    end
  end
end
