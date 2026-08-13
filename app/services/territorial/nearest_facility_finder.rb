module Territorial
  # Adequação + proximidade (seção 8 do parecer técnico): o equipamento mais próximo só
  # é sugerido se também for da categoria de serviço adequada à necessidade identificada.
  class NearestFacilityFinder
    DEFAULT_RADIUS_KM = 50
    MAX_RESULTS = 5

    def initialize(service_category: nil, municipality: nil, lat: nil, lng: nil, radius_km: DEFAULT_RADIUS_KM)
      @service_category = service_category
      @municipality = municipality
      @lat = lat
      @lng = lng
      @radius_km = radius_km
    end

    def call
      scope = Territorial::Facility.active
      scope = scope.joins(:service_categories)
        .where(territorial_service_categories: { id: @service_category.id }) if @service_category

      if @lat.present? && @lng.present?
        scope.near(lat: @lat, lng: @lng, radius_km: @radius_km).limit(MAX_RESULTS).to_a
      elsif @municipality
        scope.where(municipality_id: @municipality.id).limit(MAX_RESULTS).to_a
      else
        []
      end
    end
  end
end
