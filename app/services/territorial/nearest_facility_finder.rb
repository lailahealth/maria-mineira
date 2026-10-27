module Territorial
  # Adequação + proximidade (seção 8 do parecer técnico): o equipamento mais próximo só
  # é sugerido se também for da categoria de serviço adequada à necessidade identificada.
  # Se essa categoria não tiver nada cadastrado na região, cai para os equipamentos de
  # qualquer categoria: várias categorias (orientacao-juridica, central-180) ainda não
  # têm nenhum equipamento cadastrado, e "moro em Uberlândia, quais meus direitos?"
  # respondia "não temos serviços" mesmo com CRAS, CREAS e DEAM na cidade.
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
      if @service_category
        adequate = search(Territorial::Facility.active.joins(:service_categories)
          .where(territorial_service_categories: { id: @service_category.id }))
        return adequate if adequate.any?
      end

      search(Territorial::Facility.active)
    end

    private

    def search(scope)
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
