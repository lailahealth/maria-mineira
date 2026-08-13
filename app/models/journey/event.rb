module Journey
  # Evento estruturado da jornada (seção 15 do parecer técnico) — a peça central da
  # "escuta digital". Cada evento é um fato curto (tag/subtag/território/resultado),
  # nunca a narrativa livre da pessoa.
  class Event < AnalyticsRecord
    self.table_name = "journey_events"

    enum :event_type, {
      origem: 0,
      motivo: 1,
      busca_servico: 2,
      resultado_busca: 3,
      chatbot: 4,
      pagina_conteudo: 5
    }

    enum :resultado, { encontrado: 0, nao_encontrado: 1 }, prefix: true, allow_nil: true

    belongs_to :session, class_name: "Journey::Session", foreign_key: :journey_session_id

    validates :event_type, presence: true
  end
end
