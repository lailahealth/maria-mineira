module Territorial
  class MunicipalitiesController < ApplicationController
    def show
      @municipality = Territorial::Municipality.find_by!(ibge_code: params[:id])
      @facilities = Territorial::Facility.active.where(municipality: @municipality).includes(:service_categories)
    end
  end
end
