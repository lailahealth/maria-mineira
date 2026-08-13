class CreateTerritorialFacilities < ActiveRecord::Migration[8.1]
  def change
    enable_extension "postgis" unless extension_enabled?("postgis")

    create_table :territorial_facilities do |t|
      t.string :name, null: false
      t.string :facility_type, null: false
      t.string :address
      t.string :neighborhood
      t.string :cep
      t.references :municipality, null: false, foreign_key: { to_table: :territorial_municipalities }
      t.float :latitude
      t.float :longitude
      t.string :phone
      t.string :opening_hours
      t.text :description
      t.text :access_info
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    # Coluna geográfica (PostGIS) usada para busca por proximidade (ST_DWithin/ST_Distance).
    # Mantida em sincronia com latitude/longitude pelo model (ver Territorial::Facility).
    execute <<~SQL
      ALTER TABLE territorial_facilities
        ADD COLUMN location geography(Point, 4326)
    SQL
    add_index :territorial_facilities, :location, using: :gist
  end
end
