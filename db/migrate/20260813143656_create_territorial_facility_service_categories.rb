class CreateTerritorialFacilityServiceCategories < ActiveRecord::Migration[8.1]
  def change
    create_table :territorial_facility_service_categories do |t|
      t.references :facility, null: false, foreign_key: { to_table: :territorial_facilities }
      t.references :service_category, null: false, foreign_key: { to_table: :territorial_service_categories }

      t.timestamps
    end

    add_index :territorial_facility_service_categories, %i[facility_id service_category_id],
      unique: true, name: "index_facility_service_categories_uniqueness"
  end
end
