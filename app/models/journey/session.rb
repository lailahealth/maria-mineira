module Journey
  # Sessão anônima (identificador de jornada), guardada no banco "analytics".
  # Nenhum dado identificável é armazenado aqui — apenas origem/contexto agregável.
  class Session < AnalyticsRecord
    self.table_name = "journey_sessions"

    has_many :events, class_name: "Journey::Event", foreign_key: :journey_session_id, dependent: :destroy
    has_many :chat_turns, class_name: "Journey::ChatTurn", foreign_key: :journey_session_id, dependent: :destroy

    validates :started_at, presence: true
  end
end
