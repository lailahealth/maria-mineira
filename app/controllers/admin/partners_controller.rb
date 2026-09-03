module Admin
  class PartnersController < Admin::BaseController
    before_action { require_role!("partner_manager") }
    before_action :set_partner, only: %i[ edit update destroy ]

    def index
      @pagy, @partners = pagy(Partners::Partner.order(:name))
    end

    def new
      @partner = Partners::Partner.new
    end

    def create
      @partner = Partners::Partner.new(partner_params)
      if @partner.save
        redirect_to admin_partners_path, notice: "Parceiro criado."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @partner.update(partner_params)
        redirect_to admin_partners_path, notice: "Parceiro atualizado."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @partner.destroy
      redirect_to admin_partners_path, notice: "Parceiro removido."
    end

    private

    def set_partner
      @partner = Partners::Partner.find(params[:id])
    end

    def partner_params
      params.require(:partners_partner).permit(
        :name, :partner_type, :description, :url, :coverage_scope, :active, :logo
      )
    end
  end
end
