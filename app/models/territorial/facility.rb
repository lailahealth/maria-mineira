module Territorial
  # Equipamento/serviço mapeado (seção 17 do parecer técnico). A tabela nasce vazia
  # neste protótipo — a base real "será fornecida pela equipe" (PDF original); não
  # substituir por dados fictícios (ver seção 11 do PDF sobre municípios sem cobertura).
  class Facility < ApplicationRecord
    self.table_name = "territorial_facilities"

    belongs_to :municipality, class_name: "Territorial::Municipality"
    has_many :facility_service_categories, class_name: "Territorial::FacilityServiceCategory", dependent: :destroy
    has_many :service_categories, through: :facility_service_categories

    validates :name, presence: true
    validates :facility_type, presence: true

    scope :active, -> { where(active: true) }

    before_save :sync_location, if: -> { latitude_changed? || longitude_changed? }
    after_commit :enqueue_geocoding, on: %i[create update]

    # Equipamentos com coordenadas dentro do raio (km) de um ponto, ordenados por
    # distância (mais próximo primeiro). Cálculo feito no banco via PostGIS.
    scope :near, ->(lat:, lng:, radius_km: 50) {
      where.not(location: nil)
        .select(
          "territorial_facilities.*, " \
          "ST_Distance(location, ST_SetSRID(ST_MakePoint(#{lng.to_f}, #{lat.to_f}), 4326)::geography) AS distance_meters"
        )
        .where(
          "ST_DWithin(location, ST_SetSRID(ST_MakePoint(?, ?), 4326)::geography, ?)",
          lng.to_f, lat.to_f, radius_km * 1000
        )
        .order(Arel.sql("distance_meters ASC"))
    }

    def distance_km
      return nil unless self[:distance_meters]

      (self[:distance_meters].to_f / 1000).round(1)
    end

    # Endereço em formato de busca livre para a Nominatim (Territorial::Geocoder).
    def geocoding_query
      [address, neighborhood, municipality&.name, "MG", "Brasil"].select(&:present?).join(", ")
    end

    private

    def sync_location
      self.location = latitude.present? && longitude.present? ? "POINT(#{longitude} #{latitude})" : nil
    end

    # Só busca coordenadas quando ainda não há nenhuma (preenchida manualmente ou
    # por uma geocodificação anterior) e há endereço suficiente para tentar. Roda
    # de novo em edições futuras só se o endereço realmente mudou, para não bater
    # na Nominatim a cada save irrelevante (ex.: só ativar/desativar o equipamento).
    def enqueue_geocoding
      return unless latitude.blank? && address.present? && municipality_id.present?
      return unless previously_new_record? ||
        saved_change_to_address? || saved_change_to_neighborhood? ||
        saved_change_to_cep? || saved_change_to_municipality_id?

      GeocodeFacilityJob.perform_later(id)
    end
  end
end
