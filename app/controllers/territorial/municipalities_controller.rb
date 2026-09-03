module Territorial
  class MunicipalitiesController < ApplicationController
    def show
      @municipality = Territorial::Municipality.find_by!(ibge_code: params[:id])
      @pagy, @facilities = pagy(
        Territorial::Facility.active.where(municipality: @municipality).includes(:service_categories).order(:name)
      )
    end
  end
end
