module ApplicationCable
  # Nenhuma feature pública usa Action Cable hoje (o chat responde via Turbo
  # Stream inline no POST, sem assinatura de canal) — só a área Admin:: loga.
  # Por isso a conexão não rejeita anônimos: só identifica admin quando houver
  # uma Admin::Session válida, para uso futuro (ex.: painel ao vivo).
  class Connection < ActionCable::Connection::Base
    identified_by :current_admin_user

    def connect
      self.current_admin_user = find_admin_user
    end

    private
      def find_admin_user
        if session = Admin::Session.find_by(id: cookies.signed[:admin_session_id])
          session.user
        end
      end
  end
end
