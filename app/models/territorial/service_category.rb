module Territorial
  class ServiceCategory < ApplicationRecord
    self.table_name = "territorial_service_categories"

    belongs_to :taxonomy_tag, class_name: "Taxonomy::Tag", optional: true
    has_many :facility_service_categories, class_name: "Territorial::FacilityServiceCategory",
      foreign_key: :service_category_id, dependent: :destroy
    has_many :facilities, through: :facility_service_categories

    validates :name, presence: true
    validates :slug, presence: true, uniqueness: true

    def to_param
      slug
    end
  end
end
