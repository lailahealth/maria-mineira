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
  end
end
