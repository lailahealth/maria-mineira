module Territorial
  class FacilitiesController < ApplicationController
    def show
      @facility = Territorial::Facility.active.includes(:municipality, :service_categories).find(params[:id])
    end
  end
end
