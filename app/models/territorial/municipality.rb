module Territorial
  class Municipality < ApplicationRecord
    self.table_name = "territorial_municipalities"

    has_many :facilities, class_name: "Territorial::Facility", dependent: :restrict_with_error

    validates :ibge_code, presence: true, uniqueness: true
    validates :name, presence: true

    def to_param
      ibge_code
    end
  end
end
