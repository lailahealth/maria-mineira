module Admin
  # CRUD de Territorial::Facility (equipamentos). A tabela nasce vazia neste
  # protótipo por design (ver db/seeds.rb) — esta é a tela pela qual a equipe
  # passa a alimentar a base real.
  class FacilitiesController < Admin::BaseController
    before_action { require_role!("content_editor") }
    before_action :set_facility, only: %i[ edit update destroy ]

    def index
      @pagy, @facilities = pagy(Territorial::Facility.includes(:municipality).order(:name))
    end

    def new
      @facility = Territorial::Facility.new
    end

    def create
      @facility = Territorial::Facility.new(facility_params)
      if @facility.save
        redirect_to admin_facilities_path, notice: "Equipamento criado."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @facility.update(facility_params)
        redirect_to admin_facilities_path, notice: "Equipamento atualizado."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @facility.destroy
      redirect_to admin_facilities_path, notice: "Equipamento removido."
    end

    private

    def set_facility
      @facility = Territorial::Facility.find(params[:id])
    end

    def facility_params
      params.require(:territorial_facility).permit(
        :name, :facility_type, :municipality_id, :address, :neighborhood, :cep,
        :phone, :opening_hours, :description, :access_info, :active,
        :latitude, :longitude, service_category_ids: []
      )
    end
  end
end
