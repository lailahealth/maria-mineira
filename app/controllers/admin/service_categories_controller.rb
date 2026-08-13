module Admin
  class ServiceCategoriesController < Admin::BaseController
    before_action { require_role!("content_editor") }
    before_action :set_service_category, only: %i[ edit update destroy ]

    def index
      @service_categories = Territorial::ServiceCategory.includes(:taxonomy_tag).order(:name)
    end

    def new
      @service_category = Territorial::ServiceCategory.new
    end

    def create
      @service_category = Territorial::ServiceCategory.new(service_category_params)
      if @service_category.save
        redirect_to admin_service_categories_path, notice: "Categoria criada."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @service_category.update(service_category_params)
        redirect_to admin_service_categories_path, notice: "Categoria atualizada."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @service_category.destroy
      redirect_to admin_service_categories_path, notice: "Categoria removida."
    end

    private

    def set_service_category
      @service_category = Territorial::ServiceCategory.find_by!(slug: params[:id])
    end

    def service_category_params
      params.require(:territorial_service_category).permit(:name, :slug, :taxonomy_tag_id)
    end
  end
end
