class ApplicationController < ActionController::Base
  include Pagy::Backend

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  private

  # Identificador anônimo de sessão (Journey::Session, banco "analytics"), persistido
  # num cookie assinado — não é um login, apenas permite religar eventos da mesma
  # visita sem identificar a pessoa (seções 10/24/15 do parecer técnico).
  def current_journey_session
    @current_journey_session ||= find_or_create_journey_session
  end
  helper_method :current_journey_session

  # Conversa ativa da sessão anônima atual. Só retoma uma conversa existente se
  # ela teve atividade há menos de Chat::Conversation::INACTIVITY_TIMEOUT — depois
  # disso começa uma nova (a antiga fica para o PurgeStaleChatMessagesJob apagar).
  def current_chat_conversation
    @current_chat_conversation ||= Chat::Conversation
      .where(journey_session_id: current_journey_session.id)
      .where("chat_conversations.updated_at > ?", Chat::Conversation::INACTIVITY_TIMEOUT.ago)
      .order(created_at: :desc)
      .first || Chat::Conversation.create!(journey_session_id: current_journey_session.id)
  end
  helper_method :current_chat_conversation

  # Entrada 1 (origem por conteúdo — seção 1 do parecer técnico): quando a pessoa
  # navega por uma página de conteúdo, registramos o tema como tag_origem (só na
  # primeira vez, para manter o "primeiro toque" de conteúdo) e sempre um
  # Journey::Event de página consultada, independentemente de já haver origem
  # definida. (A campanha/UTM em si é por último toque — ver find_or_create_journey_session.)
  def record_content_origin(page)
    tag, subtag = page.taxonomy_tag&.origin_pair || [ nil, nil ]
    track_page_view(tag: tag, subtag: subtag)
  end

  # Registra a visita em páginas sem taxonomia própria (home, institucionais) —
  # sem tag/subtag, só garante que a sessão e o Journey::Event de página consultada
  # existam, para o anúncio/campanha que aponta pra elas não ficar invisível no painel.
  def track_page_view(tag: nil, subtag: nil)
    session = current_journey_session
    if session.tag_origem.blank? && tag.present?
      session.update!(tag_origem: tag, subtag_origem: subtag)
    end

    Journey::EventRecorder.record(session: session, event_type: :pagina_conteudo, tag: tag, subtag: subtag)
  end

  def find_or_create_journey_session
    id = cookies.signed[:journey_session_id]
    session = id.present? ? Journey::Session.find_by(id: id) : nil
    session ||= Journey::Session.create!(
      started_at: Time.current,
      pagina_entrada: request.fullpath
    )
    update_journey_session_utm(session)
    cookies.signed[:journey_session_id] = { value: session.id, expires: 30.days, httponly: true, same_site: :lax }
    session
  end

  # Atribuição por último toque: toda chegada com utm_* reescreve a origem da
  # sessão, mesmo que ela já tivesse uma campanha diferente antes.
  def update_journey_session_utm(session)
    return if params[:utm_source].blank? && params[:utm_campaign].blank? && params[:utm_content].blank?

    session.update!(
      plataforma_origem: params[:utm_source],
      campanha: params[:utm_campaign],
      conteudo_origem: params[:utm_content]
    )
  end
end
