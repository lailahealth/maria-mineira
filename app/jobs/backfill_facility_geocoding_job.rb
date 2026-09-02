# Geocodifica em segundo plano os equipamentos que ainda estão sem coordenadas —
# usado depois de carregar a base ampla de CRAS/CREAS/DEAMs (db/seeds/*.csv), em
# que enfileirar um GeocodeFacilityJob por registro dispararia centenas de
# requisições de uma vez e estouraria a política de uso da Nominatim (~1 req/s).
#
# Processa em lotes pequenos e reenfileira a si mesmo com um cursor por id, para
# não prender o worker por dezenas de minutos e para não reprocessar em loop os
# que falharam (ficam sem coordenadas e só são retentados num novo disparo com
# after_id zero — via `rails territorial:backfill_geocoding`).
class BackfillFacilityGeocodingJob < ApplicationJob
  queue_as :default

  BATCH_SIZE = 50
  THROTTLE_SECONDS = 1

  def perform(after_id = 0)
    batch = Territorial::Facility
      .where(latitude: nil)
      .where("id > ?", after_id)
      .order(:id)
      .limit(BATCH_SIZE)
      .to_a
    return if batch.empty?

    batch.each do |facility|
      sleep THROTTLE_SECONDS
      GeocodeFacilityJob.perform_now(facility.id)
    end

    self.class.perform_later(batch.last.id)
  end
end
