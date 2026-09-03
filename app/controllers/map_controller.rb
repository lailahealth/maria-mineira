# Busca territorial por município e/ou categoria de serviço (seção 17 do parecer
# técnico). Complementar ao chat: aqui a pessoa navega por conta própria, sem
# precisar conversar — mas usa a mesma base (Territorial::Facility).
class MapController < ApplicationController
  def index
    @municipality = find_municipality(params[:municipio])
    @service_category = Territorial::ServiceCategory.find_by(slug: params[:categoria])
    @service_categories = Territorial::ServiceCategory.order(:name)
    @searched = @municipality.present? || @service_category.present?

    @facilities =
      if @searched
        scope = Territorial::Facility.active.includes(:municipality, :service_categories)
        scope = scope.where(municipality: @municipality) if @municipality
        if @service_category
          scope = scope.joins(:service_categories)
            .where(territorial_service_categories: { id: @service_category.id })
        end
        scope.to_a
      else
        []
      end
  end

  private

  def find_municipality(query)
    Territorial::Municipality.search_by_name(query)
  end
end
