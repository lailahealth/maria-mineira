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
    end
  end
end
