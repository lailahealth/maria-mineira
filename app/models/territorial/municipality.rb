require "did_you_mean"

module Territorial
  class Municipality < ApplicationRecord
    self.table_name = "territorial_municipalities"

    has_many :facilities, class_name: "Territorial::Facility", dependent: :restrict_with_error

    validates :ibge_code, presence: true, uniqueness: true
    validates :name, presence: true

    # A acentuação some dos dois lados da comparação: a maioria das pessoas digita
    # "Vicosa", "Uberlandia", "Pocos de Caldas" sem os diacríticos, e o nome
    # cadastrado tem. translate() é nativo do Postgres — dispensa a extensão
    # unaccent (que exigiria migração e permissão de superusuário no banco).
    ACCENTED = "áàâãäçéèêëíìîïñóòôõöúùûüÁÀÂÃÄÇÉÈÊËÍÌÎÏÑÓÒÔÕÖÚÙÛÜ".freeze
    UNACCENTED = "aaaaaceeeeiiiinooooouuuuAAAAACEEEEIIIINOOOOOUUUU".freeze
    DEACCENT_SQL = "translate(lower(name), '#{ACCENTED}', '#{UNACCENTED}')".freeze

    def to_param
      ibge_code
    end

    # Busca tolerante por nome, usada no campo "município ou CEP" do chat e do
    # mapa: ignora acento e caixa, tenta igualdade exata antes de cair para
    # "contém" (menor nome primeiro, para o parcial não puxar um município maior).
    def self.search_by_name(query)
      normalized = normalize(query)
      return nil if normalized.blank?

      exact_match(query) ||
        where("#{DEACCENT_SQL} LIKE ?", "%#{sanitize_sql_like(normalized)}%").order(Arel.sql("length(name)")).first
    end

    # Só a igualdade exata (sem o fallback "contém") — usada para reconhecer um
    # nome de município dentro de uma mensagem livre do chat (Territorial::LocationResolver),
    # onde a intenção é ambígua e um "contém" arriscaria confundir uma frase comum
    # com o nome de uma cidade.
    def self.exact_match(query)
      normalized = normalize(query)
      return nil if normalized.blank?

      where("#{DEACCENT_SQL} = ?", normalized).first
    end

    def self.normalize(query)
      query.to_s.unicode_normalize(:nfkd).gsub(/\p{Mn}/, "").strip.downcase
    end

    # Tolera erro de digitação de 1-2 letras (ex.: "Jaboticatuba" por "Jaboticatubas"),
    # usada como último recurso pela detecção de localização no texto livre do chat
    # (Territorial::LocationResolver), depois que exact_match já falhou. A distância
    # aceita cresce com o tamanho do nome — nomes curtos toleram menos, para não
    # confundir uma palavra comum de poucas letras com uma cidade. Só aceita quando
    # há um único candidato mais próximo (sem empate), para não chutar entre duas
    # cidades igualmente parecidas.
    def self.fuzzy_match(query)
      normalized = normalize(query)
      return nil if normalized.blank?

      by_distance = pluck(:id, :name)
        .map { |id, name| [ id, DidYouMean::Levenshtein.distance(normalized, normalize(name)) ] }
        .sort_by { |_, distance| distance }

      best_id, best_distance = by_distance.first
      return nil if best_distance > allowed_distance(normalized.length)
      return nil if by_distance.second&.last == best_distance

      find(best_id)
    end

    def self.allowed_distance(length)
      case length
      when 0..4 then 0
      when 5..8 then 1
      else 2
      end
    end
  end
end
