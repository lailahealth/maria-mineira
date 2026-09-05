module Territorial
  # Resolve município/CEP a partir de texto — usada tanto pelo campo dedicado de
  # localização (#resolve, tolerante: aceita nome parcial de município, porque ali
  # a intenção de informar uma localização já é explícita) quanto pela detecção
  # automática de localização dentro do texto livre do chat (#resolve_strict).
  #
  # #resolve_strict é deliberadamente rígida: só reconhece a mensagem inteira como
  # localização quando ela é só um CEP ou bate exatamente com um nome de município —
  # nunca por "contém", para não confundir "moro em Uberlândia, quais meus direitos?"
  # ou "tem muita formiga aqui" com um pedido de busca por região.
  module LocationResolver
    CEP_ONLY = /\A\d{5}-?\d{3}\z/

    def self.resolve(query)
      return {} if query.blank?

      digits = query.to_s.gsub(/\D/, "")
      return resolve_cep(digits) if digits.length == 8

      municipality = Territorial::Municipality.search_by_name(query)
      municipality ? { municipality: municipality } : {}
    end

    def self.resolve_strict(text)
      trimmed = text.to_s.strip
      return {} if trimmed.blank?

      return resolve_cep(trimmed.gsub(/\D/, "")) if CEP_ONLY.match?(trimmed)

      municipality = Territorial::Municipality.exact_match(trimmed)
      municipality ? { municipality: municipality } : {}
    end

    def self.resolve_cep(digits)
      return {} unless digits.length == 8

      result = Territorial::CepLookup.lookup(digits)
      return {} unless result

      municipality = Territorial::Municipality.find_by(ibge_code: result.ibge_code)
      address_query = [ result.street, result.neighborhood, result.city, result.state, "Brasil" ].select(&:present?).join(", ")
      geocoded = Territorial::Geocoder.geocode(address_query)

      geocoded ? { lat: geocoded.latitude, lng: geocoded.longitude, municipality: municipality } : { municipality: municipality }
    end
    private_class_method :resolve_cep
  end
end
