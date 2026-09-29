module Admin
  # Painel inicial: contagens simples de conteúdo + leitura agregada de
  # Journey::Event (banco analytics), delegada a Journey::DashboardReport. Não é o
  # dashboard territorial completo da seção 20 do PDF — isso fica para uma fase
  # futura (stub, ver seção 3.7/8 do parecer técnico).
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

      report = Journey::DashboardReport.new
      @campaign_rows = report.campaigns
      @sessions_by_day = report.sessions_by_day
      @sessions_by_hour = report.sessions_by_hour
      @top_motivos = report.top_motivos
      @top_municipios = report.top_municipios
      @recent_conversas = report.recent_conversas
      @resultados_busca = report.resultados_busca
      @qualidade_respostas = report.qualidade_respostas
      @conversas_inacabadas = report.conversas_inacabadas
    end
  end
end
