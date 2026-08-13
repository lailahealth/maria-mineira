class Current < ActiveSupport::CurrentAttributes
  # Sessão de login administrativo (Admin::Session/Admin::User) — não tem relação
  # com Journey::Session, que é o identificador anônimo da usuária final.
  attribute :session
  delegate :user, to: :session, allow_nil: true
end
