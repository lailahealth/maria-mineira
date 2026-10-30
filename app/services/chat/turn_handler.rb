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

    HISTORY_LIMIT = 8

    def initialize(conversation:, journey_session:)
      @conversation = conversation
      @journey_session = journey_session
    end

    def start!
      return unless @conversation.saudacao? && @conversation.messages.none?

      say_assistant(
        "Oi, eu sou a Maria Mineira. Tem alguma situação no seu relacionamento, em casa ou na sua vida " \
        "que está te preocupando, machucando ou deixando insegura? Mesmo que você não saiba se isso é " \
        "violência, pode conversar comigo. Sua conversa é sigilosa, e eu estou preparada para te ajudar " \
        "a entender o que está acontecendo e indicar caminhos e serviços onde você pode buscar ajuda em " \
        "qualquer município de Minas Gerais. Conte, do seu jeito, o que está acontecendo."
      )
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

      # A resposta das cartilhas (chamada à IA) e a classificação (que pode chamar a
      # IA também, ver Classification::Classifier) não dependem uma da outra — em
      # paralelo, a espera do primeiro relato é a mais lenta das duas, não a soma.
      # Só a chamada HTTP do KnowledgeAnswerer vai para a thread — o histórico é lido
      # aqui, antes, para a thread não precisar de conexão própria do pool.
      history = recent_text_history
      answer_thread = Thread.new { Chat::KnowledgeAnswerer.answer(text, history: history, municipality: @conversation.municipality) }
      result = Classification::Classifier.classify(text)
      answer = answer_thread.value

      # Vai direto para o estágio livre em vez de forçar a localização: às vezes a
      # mulher só quer tirar uma dúvida, não buscar um serviço. A busca por
      # proximidade fica disponível a qualquer momento pelo botão "Buscar serviço
      # perto de você" do composer (ver #request_location), não como próximo passo
      # obrigatório.
      @conversation.update!(context_tag: result.tag_slug, service_category: unambiguous_category_for(result), stage: :livre)

      qualidade = say_answer_or_fallback(text, result, answer: answer)
      Journey::EventRecorder.record(
        session: @journey_session, event_type: :motivo, tag: result.tag_slug, subtag: result.subtag_slug,
        qualidade_resposta: qualidade
      )

      # Se o relato já disse a cidade ("moro em Juiz de Fora e meu marido…"), mostra
      # os serviços de uma vez, em vez de pedir uma localização que ela já deu.
      location = Territorial::LocationResolver.extract(text).except(:remainder)
      return receive_location(**location) if location.present?

      say_assistant(
        "Quando quiser, posso procurar um serviço perto de você — é só clicar em " \
        "\"Buscar serviço perto de você\", aqui embaixo, ou me dizer em que cidade você está.",
        card_type: :location_prompt
      )
    end

    # Acionado pelo botão "Buscar serviço perto de você" do composer (disponível a
    # qualquer momento na conversa livre) — não é mais um passo forçado logo após o
    # motivo, para não interromper quem só quer conversar/tirar dúvidas. Registra a
    # intenção de busca já aqui, separada de Journey::Event.busca_servico (só gravado
    # quando a localização é de fato informada) — a diferença entre os dois é quem
    # clicou e desistiu no meio, sem dizer cidade nem CEP.
    def request_location
      @conversation.update!(stage: :aguardando_localizacao)
      Journey::EventRecorder.record(
        session: @journey_session, event_type: :busca_solicitada,
        categoria_servico: @conversation.service_category&.slug
      )
      say_assistant("Claro! Me diga em que cidade você está (ou seu CEP), ou clique em \"Usar minha localização\".")
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
        resultado: resultado_busca_para(municipality: municipality, lat: lat, facilities: facilities),
        municipality_ibge_code: municipality&.ibge_code,
        equipamento_indicado: facilities.first,
        distancia_aproximada_km: facilities.first&.distance_km
      )

      @conversation.update!(municipality: municipality, stage: :apresentando_resultado)

      if facilities.any?
        # Diz qual cidade entendeu, em vez de "perto de você": se o reconhecimento
        # errar a cidade, a pessoa vê na hora. "Perto de você" só quando a busca foi
        # por coordenada (GPS/CEP), que é de fato a posição dela.
        intro = lat.present? || municipality.nil? ? "Encontrei estas opções perto de você:" : "Encontrei estes serviços em #{municipality.name}:"
        say_assistant(intro, card_type: :facility_results, facilities: facilities)
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

      # Se ela disser a cidade ou o CEP na própria conversa ("Estou em Juiz de Fora",
      # em vez de usar o botão "Buscar serviço perto de você"), busca os serviços —
      # ela não tem como saber que deveria digitar só o nome. Quando a mensagem
      # também traz uma pergunta ("moro em Uberlândia, quais meus direitos?"),
      # responde a pergunta e depois mostra os serviços. Ver
      # Territorial::LocationResolver#extract para o que conta como localização.
      location = Territorial::LocationResolver.extract(text)
      if location.present?
        remainder = location.delete(:remainder)
        return receive_location(**location) unless question_left?(remainder)
      end

      result = Classification::Classifier.classify(text)

      if result.classified?
        Journey::ChatTurn.create!(session: @journey_session, tag_chat: result.tag_slug, subtag_chat: result.subtag_slug)
      end

      @conversation.update!(stage: :livre)

      # A cidade dita nesta mesma mensagem ainda não está na conversa (os serviços
      # vêm depois da resposta) — a IA precisa saber dela já nesta resposta.
      qualidade = say_answer_or_fallback(
        text, result, answer: knowledge_answer(text, municipality: location[:municipality] || @conversation.municipality)
      )
      Journey::EventRecorder.record(
        session: @journey_session, event_type: :chatbot, tag: result.tag_slug, subtag: result.subtag_slug,
        qualidade_resposta: qualidade
      )

      receive_location(**location) if location.present?
    end

    private

    # O que sobra da mensagem depois de tirar a localização ainda é uma pergunta ou
    # um relato? "oi," ou "tem delegacia?" não são — a lista de serviços já responde;
    # "e ele me xinga" ou "quais meus direitos?" são.
    def question_left?(remainder)
      remainder.to_s.scan(/[a-z]+/).length >= 3
    end

    # Responde com base nas cartilhas (Chat::KnowledgeAnswerer) sempre que possível;
    # cai numa mensagem honesta quando a IA não está configurada/disponível ou não
    # tem uma resposta — usado tanto no motivo quanto no texto livre, para que a
    # primeira mensagem já receba uma resposta de verdade, não só um redirecionamento.
    # Retorna o símbolo de Journey::Event.qualidade_resposta correspondente, para
    # quem chama gravar junto do evento :motivo/:chatbot. `answer` pode vir pronta
    # de quem chama (receive_motivo a busca em paralelo com a classificação).
    def say_answer_or_fallback(text, result, answer: knowledge_answer(text))
      if answer.present?
        say_assistant(answer.text)
        return :com_conteudo
      end

      say_assistant(fallback_message(result))
      return :erro_tecnico if answer.failed?

      result.classified? ? :fallback_classificado : :nao_classificado
    end

    # Mesma mensagem de hoje independente do motivo da falta de resposta (falha
    # técnica ou simplesmente sem conteúdo) — a pessoa não precisa saber qual dos
    # dois aconteceu, só que a Maria Mineira ainda não tem uma resposta pronta;
    # a distinção fica só nos bastidores, em qualidade_resposta.
    def fallback_message(result)
      if result.classified?
        label = matched_tag(result)&.label&.downcase
        "Percebi que isso tem a ver com #{label}. Ainda estou aprendendo a explicar esse assunto com mais " \
          "profundidade — em breve vou trazer conteúdo completo sobre ele. Por enquanto, você pode conferir o " \
          "que já temos ou procurar um serviço de apoio."
      else
        "Ainda estou aprendendo a entender esse tipo de mensagem. Você pode tentar reformular, ou explorar os " \
          "conteúdos e serviços da Maria Mineira enquanto isso."
      end
    end

    # local_nao_reconhecido quando a cidade/CEP digitado não foi reconhecido (nem
    # município nem lat/lng) — diferente de nao_encontrado, onde o local é conhecido
    # mas não há equipamento cadastrado ali (ver Journey::Event#resultado).
    def resultado_busca_para(municipality:, lat:, facilities:)
      return :local_nao_reconhecido if municipality.nil? && lat.nil?

      facilities.any? ? :encontrado : :nao_encontrado
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

    def knowledge_answer(text, municipality: @conversation.municipality)
      Chat::KnowledgeAnswerer.answer(text, history: recent_text_history, municipality: municipality)
    end

    # As últimas mensagens de texto da conversa, para a IA não responder cada
    # mensagem do zero (sem isso ela "esquecia" a cidade e voltava a sugerir BH).
    # Cards (serviços, emergência, convite para busca) ficam de fora — o corpo dos
    # cards de serviço é JSON. A mensagem atual, já salva por #say_user, também.
    def recent_text_history
      messages = @conversation.messages.where(card_type: nil).order(:created_at).last(HISTORY_LIMIT + 1)
      messages = messages[0...-1] if messages.last&.user?
      messages.map { |message| { role: message.user? ? "user" : "assistant", text: message.body } }
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
