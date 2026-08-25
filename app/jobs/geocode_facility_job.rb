# Geocodifica um equipamento em segundo plano (seção 5 do parecer técnico): roda
# uma vez no cadastro/edição de endereço pela equipe, nunca por visitante — volume
# baixo o suficiente para a política de uso da Nominatim. Se o endereço não for
# encontrado, o equipamento fica sem coordenadas (não some do site: continua
# listado por município, só não aparece no mapa) — mesma lógica de honestidade do
# "ainda não temos informações suficientes" em vez de inventar uma localização.
class GeocodeFacilityJob < ApplicationJob
  queue_as :default

  def perform(facility_id)
    facility = Territorial::Facility.find_by(id: facility_id)
    return if facility.nil? || facility.latitude.present?

    result = Territorial::Geocoder.geocode(facility.geocoding_query) ||
      Territorial::Geocoder.geocode(facility.geocoding_query(precision: :neighborhood)) ||
      Territorial::Geocoder.geocode(facility.geocoding_query(precision: :municipality))
    return if result.nil?

    facility.update!(latitude: result.latitude, longitude: result.longitude)
  end
end
