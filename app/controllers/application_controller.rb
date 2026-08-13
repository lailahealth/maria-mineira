class ApplicationController < ActionController::Base
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

  # Conversa ativa da sessão anônima atual (cria uma se ainda não existir).
  def current_chat_conversation
    @current_chat_conversation ||= Chat::Conversation
      .where(journey_session_id: current_journey_session.id)
      .order(created_at: :desc)
      .first_or_create!(journey_session_id: current_journey_session.id)
  end
  helper_method :current_chat_conversation

  # Entrada 1 (origem por conteúdo — seção 1 do parecer técnico): quando a pessoa
  # navega por uma página de conteúdo, registramos o tema como tag_origem (só na
  # primeira vez, para manter o "primeiro toque") e sempre um Journey::Event de
  # página consultada, independentemente de já haver origem definida.
  def record_content_origin(page)
    tag, subtag = page.taxonomy_tag&.origin_pair || [nil, nil]

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
      plataforma_origem: params[:utm_source],
      campanha: params[:utm_campaign],
      conteudo_origem: params[:utm_content],
      pagina_entrada: request.fullpath
    )
    cookies.signed[:journey_session_id] = { value: session.id, expires: 30.days, httponly: true, same_site: :lax }
    session
  end
end
