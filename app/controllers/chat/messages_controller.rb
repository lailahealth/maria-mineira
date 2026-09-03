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
          handler.receive_location(**resolve_location(params[:municipio]))
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

    # Aceita tanto nome de município quanto CEP no mesmo campo (seção 6.1 do
    # parecer técnico: ViaCEP é gratuita e devolve o código IBGE do município,
    # dispensando busca fuzzy por nome nesse caso).
    def resolve_location(query)
      return {} if query.blank?

      digits = query.to_s.gsub(/\D/, "")
      return resolve_cep(digits) if digits.length == 8

      { municipality: find_municipality(query) }
    end

    def resolve_cep(digits)
      result = Territorial::CepLookup.lookup(digits)
      return {} unless result

      municipality = Territorial::Municipality.find_by(ibge_code: result.ibge_code)
      address_query = [ result.street, result.neighborhood, result.city, result.state, "Brasil" ].select(&:present?).join(", ")
      geocoded = Territorial::Geocoder.geocode(address_query)

      geocoded ? { lat: geocoded.latitude, lng: geocoded.longitude, municipality: municipality } : { municipality: municipality }
    end

    def find_municipality(query)
      Territorial::Municipality.search_by_name(query)
    end
  end
end
