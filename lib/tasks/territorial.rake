namespace :territorial do
  desc "Geocodifica (síncrono, ~1 req/s) todos os equipamentos ainda sem coordenadas"
  task backfill_geocoding: :environment do
    scope = Territorial::Facility.where(latitude: nil).order(:id)
    total = scope.count
    puts "#{total} equipamento(s) sem coordenadas. Geocodificando a ~1 req/s..."

    done = 0
    scope.find_each do |facility|
      sleep 1
      GeocodeFacilityJob.perform_now(facility.id)
      done += 1
      puts "  #{done}/#{total}..." if (done % 50).zero?
    end

    geocoded = Territorial::Facility.where.not(latitude: nil).count
    puts "Concluído. #{geocoded}/#{Territorial::Facility.count} equipamentos com coordenadas."
  end
end
