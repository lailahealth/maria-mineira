require "net/http"
require "json"

module Territorial
  # Resolve CEP -> endereço via ViaCEP (seção 6.1 do parecer técnico): gratuita,
  # mantida há anos, devolve inclusive o código IBGE do município — o que permite
  # ligar direto a um Territorial::Municipality já cadastrado, sem busca fuzzy por
  # nome. Usada pelo Chat::MessagesController quando a usuária informa CEP em vez
  # de nome de município na etapa de localização.
  class CepLookup
    Result = Struct.new(:street, :neighborhood, :city, :state, :ibge_code, keyword_init: true)

    ENDPOINT = "https://viacep.com.br/ws/%s/json/"

    def self.lookup(cep)
      new.lookup(cep)
    end

    def lookup(cep)
      digits = cep.to_s.gsub(/\D/, "")
      return nil unless digits.length == 8

      response = fetch(digits)
      return nil unless response.is_a?(Net::HTTPSuccess)

      data = JSON.parse(response.body)
      return nil if data["erro"]

      Result.new(
        street: data["logradouro"], neighborhood: data["bairro"],
        city: data["localidade"], state: data["uf"], ibge_code: data["ibge"]
      )
    rescue StandardError => e
      Rails.logger.warn("[Territorial::CepLookup] falhou para #{cep.inspect}: #{e.class} #{e.message}")
      nil
    end

    private

    def fetch(digits)
      uri = URI(format(ENDPOINT, digits))
      Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: 5, read_timeout: 5) { |http| http.get(uri) }
    end
  end
end
