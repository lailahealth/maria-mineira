module Chat
  # Máquina de estágios da conversa (seção 3.2.1 do parecer técnico): motivo e
  # localização são turnos dentro do próprio chat — não telas de formulário separadas.
  # Não pede para a pessoa repetir a história: o contexto de origem/motivo já
  # coletado é reaproveitado nos turnos seguintes.
  class TurnHandler
    # Sinais de risco iminente à vida. Quando aparecem no texto livre, a Maria Mineira
    # não tenta "resolver" a situação — mostra na hora o direcionamento de emergência
    # (190 / 180), como orienta o rodapé do site, antes de qualquer classificação ou
    # busca por serviço (seção do PDF original sobre "não substituir atendimento de
    # emergência"). Lista propositalmente restrita a perigo físico imediato para não
    # disparar o card em toda mensagem urgente; deve ser revista com a equipe.
    EMERGENCY_PHRASES = [
      "vai me matar", "quer me matar", "ele vai me matar", "me matar", "vai me bater",
      "ameaca de morte", "ameacando de morte", "ameacou de morte", "morrer",
      "arma", "arma de fogo", "revolver", "faca", "esta armado", "ta armado", "pegou a arma",
      "socorro", "risco de vida", "correndo risco", "minha vida corre perigo", "estou em perigo",
      "trancada", "presa em casa", "nao consigo sair", "me trancou",
      "ele esta aqui agora", "ele ta aqui agora", "batendo em mim agora", "esta me batendo",
      "acabou de me bater", "me perseguindo agora"
    ].freeze

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
      warn_emergency_if_needed(text)
      result = Classification::Classifier.classify(text)

      Journey::EventRecorder.record(
        session: @journey_session, event_type: :motivo, tag: result.tag_slug, subtag: result.subtag_slug
      )

      # Vai direto para o estágio livre em vez de forçar a localização: às vezes a
      # mulher só quer tirar uma dúvida, não buscar um serviço. A busca por
      # proximidade fica disponível a qualquer momento pelo botão "Buscar serviço
      # perto de você" do composer (ver #request_location), não como próximo passo
      # obrigatório.
      @conversation.update!(context_tag: result.tag_slug, service_category: unambiguous_category_for(result), stage: :livre)

      say_answer_or_fallback(text, result)
      say_assistant(
        "Quando quiser, posso procurar um serviço perto de você — é só clicar em " \
        "\"Buscar serviço perto de você\", aqui embaixo.",
        card_type: :location_prompt
      )
    end

    # Acionado pelo botão "Buscar serviço perto de você" do composer (disponível a
    # qualquer momento na conversa livre) — não é mais um passo forçado logo após o
    # motivo, para não interromper quem só quer conversar/tirar dúvidas.
    def request_location
      @conversation.update!(stage: :aguardando_localizacao)
      say_assistant("Claro! Me diga sua cidade, CEP, ou clique em \"Usar minha localização\".")
    end

    # Desiste da busca por localização e volta para a conversa livre — a única porta
    # de entrada em :aguardando_localizacao agora é #request_location, então precisa
    # de uma porta de saída caso a pessoa mude de ideia.
    def cancel_location_request
      @conversation.update!(stage: :livre)
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
      warn_emergency_if_needed(text)

      # Se ela digitar só uma cidade ou um CEP na própria conversa (em vez de usar o
      # botão "Buscar serviço perto de você"), trata como localização em vez de
      # tentar responder como se fosse uma pergunta — resolve_strict só reconhece
      # quando a mensagem inteira é isso, para não confundir uma frase comum com
      # nome de cidade (ver Territorial::LocationResolver).
      location = Territorial::LocationResolver.resolve_strict(text)
      return receive_location(**location) if location.present?

      result = Classification::Classifier.classify(text)

      if result.classified?
        Journey::ChatTurn.create!(session: @journey_session, tag_chat: result.tag_slug, subtag_chat: result.subtag_slug)
      end
      Journey::EventRecorder.record(session: @journey_session, event_type: :chatbot, tag: result.tag_slug, subtag: result.subtag_slug)

      @conversation.update!(stage: :livre)

      say_answer_or_fallback(text, result)
    end

    private

    # Responde com base nas cartilhas (Chat::KnowledgeAnswerer) sempre que possível;
    # cai numa mensagem honesta quando a IA não está configurada/disponível ou não
    # tem uma resposta — usado tanto no motivo quanto no texto livre, para que a
    # primeira mensagem já receba uma resposta de verdade, não só um redirecionamento.
    def say_answer_or_fallback(text, result)
      answer = Chat::KnowledgeAnswerer.answer(text)

      if answer.present?
        say_assistant(answer)
      elsif result.classified?
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

    # Mostra o direcionamento de emergência no máximo uma vez por conversa — repetir
    # o alerta a cada mensagem afobaria a leitura sem acrescentar informação.
    def warn_emergency_if_needed(text)
      return unless emergency?(text)
      return if @conversation.messages.card_type_emergencia.exists?

      say_assistant(
        "Se você está em perigo agora, ligue 190 — a Polícia Militar atende 24 horas. " \
        "A Central de Atendimento à Mulher (180) também funciona 24 horas, é gratuita e orienta o que fazer. " \
        "A Maria Mineira é um canal de informação e não substitui o atendimento de emergência.",
        card_type: :emergencia
      )
    end

    def emergency?(text)
      normalized = text.to_s.downcase.unicode_normalize(:nfkd).gsub(/[^\x00-\x7F]/, "")
      words = normalized.split(/[^a-z0-9]+/)

      EMERGENCY_PHRASES.any? do |phrase|
        # Frases (com espaço) casam por substring; palavras isoladas ("arma", "faca")
        # casam só como token inteiro, para não pegar "armario", "alarma", "farmacia".
        phrase.include?(" ") ? normalized.include?(phrase) : words.include?(phrase)
      end
    end

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
