module Admin
  # Só leitura: municípios vêm da API do IBGE (db/seeds.rb), não são cadastrados
  # manualmente — ver seção 6.1 do parecer técnico. Esta tela existe para a
  # equipe enxergar cobertura (quantos equipamentos por município), não para editar.
  class MunicipalitiesController < Admin::BaseController
    before_action { require_role!("content_editor", "data_analyst") }

    def index
      scope = Territorial::Municipality
        .left_joins(:facilities)
        .select("territorial_municipalities.*, COUNT(territorial_facilities.id) AS facilities_count")
        .group("territorial_municipalities.id")
        .order(:name)

      scope = scope.where("territorial_municipalities.name ILIKE ?", "%#{params[:q]}%") if params[:q].present?

      @pagy, @municipalities = pagy(scope)
    end

    def show
      @municipality = Territorial::Municipality.find_by!(ibge_code: params[:id])
      @pagy, @facilities = pagy(@municipality.facilities.order(:name))
    end
  end
end
