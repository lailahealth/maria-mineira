# Busca territorial por município e/ou categoria de serviço (seção 17 do parecer
# técnico). Complementar ao chat: aqui a pessoa navega por conta própria, sem
# precisar conversar — mas usa a mesma base (Territorial::Facility).
class MapController < ApplicationController
  # Busca sem município (só por categoria) acima disso pede para escolher um
  # município: "UBS" no estado inteiro são ~5,4 mil pontos — 3,4 MB de página e
  # milhares de cartões, que travam o celular e não ajudam ninguém a achar a UBS
  # do bairro.
  STATEWIDE_LIMIT = 300

  def index
    @municipality = find_municipality(params[:municipio])
    @service_category = Territorial::ServiceCategory.find_by(slug: params[:categoria])
    @service_categories = Territorial::ServiceCategory.order(:name)
    @searched = @municipality.present? || @service_category.present?
    @facilities = []
    return unless @searched

    scope = Territorial::Facility.active
    scope = scope.where(municipality: @municipality) if @municipality
    if @service_category
      scope = scope.joins(:service_categories)
        .where(territorial_service_categories: { id: @service_category.id })
    end

    if @municipality.nil? && (@statewide_count = scope.count) > STATEWIDE_LIMIT
      @too_broad = true
      return
    end

    @facilities = scope.includes(:municipality, :service_categories).order(:name).to_a
  end

  private

  def find_municipality(query)
    Territorial::Municipality.search_by_name(query)
  end
end
