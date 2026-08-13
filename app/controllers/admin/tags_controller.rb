module Admin
  class TagsController < Admin::BaseController
    before_action { require_role!("content_editor") }
    before_action :set_tag, only: %i[ edit update destroy ]

    def index
      @tags = Taxonomy::Tag.includes(:parent).order(:kind, :position, :label)
    end

    def new
      @tag = Taxonomy::Tag.new
    end

    def create
      @tag = Taxonomy::Tag.new(tag_params)
      if @tag.save
        redirect_to admin_tags_path, notice: "Tag criada."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @tag.update(tag_params)
        redirect_to admin_tags_path, notice: "Tag atualizada."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @tag.destroy
      redirect_to admin_tags_path, notice: "Tag removida."
    end

    private

    def set_tag
      @tag = Taxonomy::Tag.find_by!(slug: params[:id])
    end

    def tag_params
      params.require(:taxonomy_tag).permit(:slug, :label, :kind, :parent_id, :active, :position)
    end
  end
end
