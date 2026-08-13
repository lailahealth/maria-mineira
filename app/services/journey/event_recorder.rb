module Journey
  # Grava eventos de forma consistente (seção 15 do parecer técnico). Usado por todos
  # os controllers públicos — nunca grava texto livre, apenas fatos estruturados.
  class EventRecorder
    def self.record(session:, event_type:, **attrs)
      new(session).record(event_type: event_type, **attrs)
    end

    def initialize(session)
      @session = session
    end

    def record(event_type:, tag: nil, subtag: nil, municipality_ibge_code: nil, categoria_servico: nil,
               equipamento_indicado: nil, resultado: nil, distancia_aproximada_km: nil)
      Journey::Event.create!(
        session: @session,
        event_type: event_type,
        tag: tag,
        subtag: subtag,
        municipality_ibge_code: municipality_ibge_code,
        categoria_servico: categoria_servico,
        equipamento_indicado_id: equipamento_indicado&.id,
        equipamento_indicado_nome: equipamento_indicado&.name,
        resultado: resultado,
        distancia_aproximada_km: distancia_aproximada_km
      )
    end
  end
end
