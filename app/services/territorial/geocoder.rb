require "net/http"
require "json"

module Territorial
  # Geocodificação de endereço → coordenadas via Nominatim/OpenStreetMap (seção 6.2
  # do parecer técnico): gratuita, adequada porque aqui é a equipe cadastrando um
  # equipamento (baixíssimo volume), não a visitante buscando — diferente do caso
  # de uso que exigiria um provedor pago com SLA. Respeita a política de uso da
  # Nominatim (https://operations.osmfoundation.org/policies/nominatim/): identifica
  # a aplicação via User-Agent e faz no máximo 1 requisição por chamada.
  class Geocoder
    ENDPOINT = URI("https://nominatim.openstreetmap.org/search")
    USER_AGENT = "MariaMineira-Prototype/1.0 (+https://mariamineira.com.br)"

    Result = Struct.new(:latitude, :longitude, keyword_init: true)

    def self.geocode(query)
      new.geocode(query)
    end

    def geocode(query)
      return nil if query.blank?

      response = fetch(query)
      return nil unless response.is_a?(Net::HTTPSuccess)

      results = JSON.parse(response.body)
      return nil if results.empty?

      Result.new(latitude: results.first["lat"].to_f, longitude: results.first["lon"].to_f)
    rescue StandardError => e
      Rails.logger.warn("[Territorial::Geocoder] falhou para #{query.inspect}: #{e.class} #{e.message}")
      nil
    end

    private

    def fetch(query)
      uri = ENDPOINT.dup
      uri.query = URI.encode_www_form(format: "jsonv2", limit: 1, countrycodes: "br", q: query)

      request = Net::HTTP::Get.new(uri)
      request["User-Agent"] = USER_AGENT

      Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: 5, read_timeout: 5) do |http|
        http.request(request)
      end
    end
  end
end
