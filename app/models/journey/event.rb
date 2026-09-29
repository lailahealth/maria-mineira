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
      pagina_conteudo: 5,
      chat_aberto: 6,
      busca_solicitada: 7,
      conversa_inacabada: 8
    }

    # local_nao_reconhecido: a busca foi tentada mas a cidade/CEP digitado não foi
    # reconhecido (diferente de nao_encontrado, onde o local é conhecido mas não há
    # equipamento cadastrado ali) — ver Chat::TurnHandler#receive_location.
    enum :resultado, { encontrado: 0, nao_encontrado: 1, local_nao_reconhecido: 2 }, prefix: true, allow_nil: true

    # O que a resposta da Maria Mineira entregou num evento :motivo/:chatbot — a
    # distinção entre "não entendemos a mensagem" e "a IA falhou tecnicamente" é o
    # sinal de erro que falta hoje (ver Chat::KnowledgeAnswerer::Answer).
    enum :qualidade_resposta, {
      com_conteudo: 0,
      fallback_classificado: 1,
      nao_classificado: 2,
      erro_tecnico: 3
    }, prefix: true, allow_nil: true

    belongs_to :session, class_name: "Journey::Session", foreign_key: :journey_session_id

    validates :event_type, presence: true
  end
end
