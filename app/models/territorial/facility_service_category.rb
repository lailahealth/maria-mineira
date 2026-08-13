module Territorial
  class FacilityServiceCategory < ApplicationRecord
    self.table_name = "territorial_facility_service_categories"

    belongs_to :facility, class_name: "Territorial::Facility"
    belongs_to :service_category, class_name: "Territorial::ServiceCategory"

    validates :facility_id, uniqueness: { scope: :service_category_id }
  end
end
