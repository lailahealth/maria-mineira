module Journey
  # Agrega a "escuta digital" (banco analytics) para o painel admin: campanhas por
  # UTM, movimento por dia e por horário, principais motivos e principais
  # municípios, e as últimas conversas. Sempre a partir de fatos estruturados
  # (Journey::Session / Journey::Event) — nunca do texto livre da pessoa.
  class DashboardReport
    # Os horários guardados estão em UTC (a app não define config.time_zone);
    # para a equipe em MG, os recortes por dia/hora são convertidos para cá.
    TIME_ZONE = "America/Sao_Paulo".freeze
    RECENT_DAYS = 14
    TOP_N = 10
    RECENT_LIMIT = 25

    # Rótulo legível para o estágio (Chat::Conversation#stage) em que uma conversa
    # expurgada parou — ver #conversas_inacabadas.
    STAGE_LABELS = {
      "saudacao" => "Abriu o chat, sem chegar a ser cumprimentada",
      "aguardando_motivo" => "Foi cumprimentada e não respondeu",
      "aguardando_localizacao" => "Pediu busca e não informou cidade/CEP",
      "apresentando_resultado" => "Recebeu o resultado da busca e não voltou",
      "livre" => "Recebeu uma resposta e não voltou a escrever"
    }.freeze

    def campaigns
      sessions = Session.where.not(plataforma_origem: [ nil, "" ])
      return [] if sessions.none?

      ids = sessions.ids
      abriram_chat = session_ids_with_event(ids, :chat_aberto)
      escreveram = session_ids_with_event(ids, :motivo, :chatbot)
      pediram_busca = session_ids_with_event(ids, :busca_solicitada)
      buscaram = session_ids_with_event(ids, :busca_servico)
      encontraram = Event.resultado_busca.resultado_encontrado
        .where(journey_session_id: ids).distinct.pluck(:journey_session_id).to_set

      sessions
        .group_by { |s| [ s.plataforma_origem, s.campanha.presence, s.conteudo_origem.presence ] }
        .map do |(plataforma, campanha, conteudo), group|
          group_ids = group.map(&:id)
          {
            plataforma: plataforma,
            campanha: campanha || "—",
            conteudo: conteudo || "—",
            sessoes: group_ids.size,
            abriram_chat: group_ids.count { |id| abriram_chat.include?(id) },
            escreveram: group_ids.count { |id| escreveram.include?(id) },
            pediram_busca: group_ids.count { |id| pediram_busca.include?(id) },
            buscaram: group_ids.count { |id| buscaram.include?(id) },
            encontraram: group_ids.count { |id| encontraram.include?(id) }
          }
        end
        .sort_by { |row| [ row[:plataforma], -row[:sessoes] ] }
    end

    # Sessões iniciadas por dia nos últimos RECENT_DAYS dias (fuso de MG),
    # incluindo os dias sem nenhuma sessão para o gráfico não "pular" datas.
    def sessions_by_day
      first_day = (RECENT_DAYS - 1).days.ago.in_time_zone(TIME_ZONE).to_date
      counts = Session
        .where(started_at: first_day.in_time_zone(TIME_ZONE).beginning_of_day..)
        .pluck(:started_at)
        .each_with_object(Hash.new(0)) { |ts, acc| acc[ts.in_time_zone(TIME_ZONE).to_date] += 1 }

      (first_day..Date.current.in_time_zone(TIME_ZONE).to_date).map do |date|
        { date: date, count: counts[date] }
      end
    end

    # Sessões por hora do dia (0–23, fuso de MG), sobre toda a base — ajuda a
    # entender quando a divulgação alcança mais gente.
    def sessions_by_hour
      counts = Session.pluck(:started_at)
        .each_with_object(Hash.new(0)) { |ts, acc| acc[ts.in_time_zone(TIME_ZONE).hour] += 1 }

      (0..23).map { |hour| { hour: hour, count: counts[hour] } }
    end

    # O que a pessoa disse que buscava, a partir dos eventos :motivo classificados.
    def top_motivos
      raw = Event.motivo.group(:tag, :subtag).count
      labels = tag_labels(raw.keys.flatten)

      raw.sort_by { |_, count| -count }.first(TOP_N).map do |(tag, subtag), count|
        { label: motivo_label(tag, subtag, labels), count: count }
      end
    end

    # Municípios mais procurados na busca por serviço (uma contagem por sessão).
    def top_municipios
      pairs = Event.busca_servico
        .where.not(municipality_ibge_code: [ nil, "" ])
        .distinct.pluck(:journey_session_id, :municipality_ibge_code)

      counts = pairs.group_by(&:last).transform_values(&:size)
      names = municipality_names(counts.keys)

      counts.sort_by { |_, count| -count }.first(TOP_N).map do |ibge_code, count|
        { municipio: names[ibge_code] || "IBGE #{ibge_code}", count: count }
      end
    end

    # Últimas conversas: data/hora do :motivo, assunto e — se a pessoa chegou a
    # buscar um serviço — o município e a origem (campanha) da sessão.
    def recent_conversas
      events = Event.motivo.order(created_at: :desc).limit(RECENT_LIMIT).to_a
      return [] if events.empty?

      session_ids = events.map(&:journey_session_id)
      sessions = Session.where(id: session_ids).index_by(&:id)
      municipio_by_session = Event.busca_servico
        .where(journey_session_id: session_ids)
        .where.not(municipality_ibge_code: [ nil, "" ])
        .order(:created_at)
        .pluck(:journey_session_id, :municipality_ibge_code)
        .to_h
      names = municipality_names(municipio_by_session.values)
      labels = tag_labels(events.flat_map { |e| [ e.tag, e.subtag ] })

      events.map do |event|
        session = sessions[event.journey_session_id]
        {
          at: event.created_at,
          motivo: motivo_label(event.tag, event.subtag, labels),
          municipio: names[municipio_by_session[event.journey_session_id]],
          origem: session_origem(session)
        }
      end
    end

    # Resultado das tentativas de busca por serviço: achou equipamento, não achou
    # (local reconhecido, sem cobertura ali) ou não reconheceu a cidade/CEP digitado
    # (ver Journey::Event#resultado).
    def resultados_busca
      base = Event.resultado_busca
      {
        encontrado: base.resultado_encontrado.count,
        nao_encontrado: base.resultado_nao_encontrado.count,
        local_nao_reconhecido: base.resultado_local_nao_reconhecido.count
      }
    end

    # Qualidade das respostas dadas nos eventos :motivo/:chatbot: resposta com
    # conteúdo das cartilhas, resposta genérica (assunto identificado mas sem
    # conteúdo pronto), mensagem não compreendida (sinal de confusão/fora do
    # escopo), ou falha técnica da IA de resposta (Chat::KnowledgeAnswerer).
    def qualidade_respostas
      base = Event.where(event_type: [ :motivo, :chatbot ])
      {
        com_conteudo: base.qualidade_resposta_com_conteudo.count,
        fallback_classificado: base.qualidade_resposta_fallback_classificado.count,
        nao_classificado: base.qualidade_resposta_nao_classificado.count,
        erro_tecnico: base.qualidade_resposta_erro_tecnico.count
      }
    end

    # Conversas expurgadas por inatividade (PurgeStaleChatMessagesJob), por estágio
    # em que pararam — do maior sinal de fricção (nunca chegou a contar o motivo) ao
    # desfecho mais comum (recebeu resposta/resultado e não voltou).
    def conversas_inacabadas
      Event.conversa_inacabada.group(:tag).count
        .map { |stage, count| { estagio: STAGE_LABELS[stage] || stage, count: count } }
        .sort_by { |row| -row[:count] }
    end

    private

    def session_ids_with_event(session_ids, *event_types)
      Event
        .where(journey_session_id: session_ids, event_type: event_types)
        .distinct.pluck(:journey_session_id).to_set
    end

    def tag_labels(slugs)
      slugs = slugs.compact.uniq
      return {} if slugs.empty?

      Taxonomy::Tag.where(slug: slugs).pluck(:slug, :label).to_h
    end

    def municipality_names(ibge_codes)
      ibge_codes = ibge_codes.compact.uniq
      return {} if ibge_codes.empty?

      Territorial::Municipality.where(ibge_code: ibge_codes).pluck(:ibge_code, :name).to_h
    end

    def motivo_label(tag, subtag, labels)
      parts = [ tag, subtag ].compact.map { |slug| labels[slug] || slug.humanize }
      parts.any? ? parts.join(" · ") : "Não classificado"
    end

    def session_origem(session)
      return nil unless session

      [ session.plataforma_origem, session.campanha ].compact_blank.join(" / ").presence
    end
  end
end
