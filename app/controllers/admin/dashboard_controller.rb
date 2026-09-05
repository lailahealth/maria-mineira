module Admin
  # Painel inicial: contagens simples de conteúdo + leitura agregada de
  # Journey::Event (banco analytics). Não é o dashboard territorial completo da
  # seção 20 do PDF — isso fica para uma fase futura (stub, ver seção 3.7/8 do
  # parecer técnico).
  class DashboardController < Admin::BaseController
    def index
      @counts = {
        "Páginas de conteúdo publicadas" => Content::Page.published.count,
        "Equipamentos ativos" => Territorial::Facility.active.count,
        "Municípios cadastrados" => Territorial::Municipality.count,
        "Parceiros ativos" => Partners::Partner.active.count,
        "Tags de taxonomia ativas" => Taxonomy::Tag.active.count
      }

      @journey_counts = {
        "Sessões anônimas registradas" => Journey::Session.count,
        "Eventos de jornada registrados" => Journey::Event.count
      }

      @campaign_rows = campaign_rows
    end

    private

    # Sessões que chegaram por link com UTM (ver
    # ApplicationController#find_or_create_journey_session: utm_source ->
    # plataforma_origem, utm_campaign -> campanha, utm_content -> conteudo_origem),
    # agrupadas por origem, com o funil até escrever no chat, buscar um serviço e
    # receber um resultado. "Primeiro toque": o UTM só é gravado na primeira
    # visita de cada sessão anônima.
    def campaign_rows
      sessions = Journey::Session.where.not(plataforma_origem: [ nil, "" ])
      return [] if sessions.none?

      ids = sessions.ids
      escreveram = session_ids_with_event(ids, :motivo, :chatbot)
      buscaram = session_ids_with_event(ids, :busca_servico)
      encontraram = Journey::Event.resultado_busca.resultado_encontrado
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
            escreveram: group_ids.count { |id| escreveram.include?(id) },
            buscaram: group_ids.count { |id| buscaram.include?(id) },
            encontraram: group_ids.count { |id| encontraram.include?(id) }
          }
        end
        .sort_by { |row| [ row[:plataforma], -row[:sessoes] ] }
    end

    def session_ids_with_event(session_ids, *event_types)
      Journey::Event
        .where(journey_session_id: session_ids, event_type: event_types)
        .distinct.pluck(:journey_session_id).to_set
    end
  end
end
