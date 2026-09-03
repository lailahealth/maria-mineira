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
      normalized = query.to_s.unicode_normalize(:nfkd).gsub(/\p{Mn}/, "").strip.downcase
      return nil if normalized.blank?

      where("#{DEACCENT_SQL} = ?", normalized).first ||
        where("#{DEACCENT_SQL} LIKE ?", "%#{sanitize_sql_like(normalized)}%").order(Arel.sql("length(name)")).first
    end
  end
end
