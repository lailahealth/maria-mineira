module Chat
  # Máquina de estágios da conversa (seção 3.2.1 do parecer técnico): motivo e
  # localização são turnos dentro do próprio chat — não telas de formulário separadas.
  # Não pede para a pessoa repetir a história: o contexto de origem/motivo já
  # coletado é reaproveitado nos turnos seguintes.
  class TurnHandler
    def initialize(conversation:, journey_session:)
      @conversation = conversation
      @journey_session = journey_session
    end

    def start!
      return unless @conversation.saudacao? && @conversation.messages.none?

      say_assistant("Como a Maria Mineira pode te ajudar hoje? Pode escrever com suas próprias palavras.")
      @conversation.update!(stage: :aguardando_motivo)

      return unless @journey_session.tag_origem.present?

      Journey::EventRecorder.record(
        session: @journey_session, event_type: :origem,
        tag: @journey_session.tag_origem, subtag: @journey_session.subtag_origem
      )
    end

    def receive_motivo(text)
      return if text.blank?

      say_user(text)
      result = Classification::Classifier.classify(text)

      Journey::EventRecorder.record(
        session: @journey_session, event_type: :motivo, tag: result.tag_slug, subtag: result.subtag_slug
      )

      @conversation.update!(context_tag: result.tag_slug, service_category: unambiguous_category_for(result), stage: :aguardando_localizacao)

      if result.classified?
        label = matched_tag(result)&.label&.downcase
        say_assistant("Entendi. Isso pode estar relacionado a #{label}. Vou te ajudar a encontrar orientação e serviços sobre isso.")
      else
        say_assistant("Entendi. Vou te ajudar a encontrar orientação e serviços que possam ajudar.")
      end

      say_assistant("Quer que eu procure um serviço perto de você?", card_type: :location_prompt)
    end

    def receive_location(lat: nil, lng: nil, municipality: nil)
      facilities = Territorial::NearestFacilityFinder.new(
        service_category: @conversation.service_category, municipality: municipality, lat: lat, lng: lng
      ).call

      Journey::EventRecorder.record(
        session: @journey_session, event_type: :busca_servico,
        categoria_servico: @conversation.service_category&.slug,
        municipality_ibge_code: municipality&.ibge_code
      )
      Journey::EventRecorder.record(
        session: @journey_session, event_type: :resultado_busca,
        resultado: facilities.any? ? :encontrado : :nao_encontrado,
        municipality_ibge_code: municipality&.ibge_code,
        equipamento_indicado: facilities.first,
        distancia_aproximada_km: facilities.first&.distance_km
      )

      @conversation.update!(municipality: municipality, stage: :apresentando_resultado)

      if facilities.any?
        say_assistant("Encontrei estas opções perto de você:", card_type: :facility_results, facilities: facilities)
      else
        onde = municipality ? " em #{municipality.name}" : " nessa localização"
        say_assistant(
          "Ainda não temos informações suficientes sobre serviços cadastrados#{onde}. " \
          "Isso não significa que não exista ajuda disponível — posso continuar te orientando.",
          card_type: :municipio_sem_cobertura
        )
      end

      say_assistant("Se quiser, posso continuar te ajudando ou explicar melhor seus direitos. É só me contar.")
    end

    def receive_free_text(text)
      return if text.blank?

      say_user(text)
      result = Classification::Classifier.classify(text)

      if result.classified?
        Journey::ChatTurn.create!(session: @journey_session, tag_chat: result.tag_slug, subtag_chat: result.subtag_slug)
      end
      Journey::EventRecorder.record(session: @journey_session, event_type: :chatbot, tag: result.tag_slug, subtag: result.subtag_slug)

      @conversation.update!(stage: :livre)

      if result.classified?
        label = matched_tag(result)&.label&.downcase
        say_assistant(
          "Percebi que isso tem a ver com #{label}. Ainda estou aprendendo a explicar esse assunto com mais " \
          "profundidade — em breve vou trazer conteúdo completo sobre ele. Por enquanto, você pode conferir o " \
          "que já temos ou procurar um serviço de apoio."
        )
      else
        say_assistant(
          "Ainda estou aprendendo a entender esse tipo de mensagem. Você pode tentar reformular, ou explorar os " \
          "conteúdos e serviços da Maria Mineira enquanto isso."
        )
      end
    end

    private

    def matched_tag(result)
      Taxonomy::Tag.find_by(slug: result.subtag_slug || result.tag_slug)
    end

    # Só filtra a busca por uma categoria de serviço quando a tag encontrada aponta
    # para exatamente uma categoria. Várias categorias (deam, casa-de-abrigo, cras,
    # creas, central-180) compartilham a tag ampla "servicos_e_equipamentos" —
    # escolher uma arbitrariamente (find_by pegando a primeira) excluiria da busca
    # por proximidade equipamentos de categorias igualmente válidas para o mesmo motivo.
    def unambiguous_category_for(result)
      categories = Territorial::ServiceCategory.where(taxonomy_tag_id: matched_tag(result)&.id)
      categories.count == 1 ? categories.first : nil
    end

    def say_user(text)
      @conversation.messages.create!(role: :user, body: text)
    end

    # facilities: array já ordenado por Territorial::NearestFacilityFinder — os ids
    # e distâncias são serializados juntos (mesmo índice) porque uma nova consulta
    # ao renderizar a mensagem perderia tanto a ordem quanto o distance_meters
    # (só existe no resultado anotado por Territorial::Facility.near, não na tabela).
    def say_assistant(text, card_type: nil, facilities: nil)
      body = facilities ? { text: text, facility_ids: facilities.map(&:id), distances_km: facilities.map(&:distance_km) }.to_json : text
      @conversation.messages.create!(role: :assistant, body: body, card_type: card_type)
    end
  end
end
