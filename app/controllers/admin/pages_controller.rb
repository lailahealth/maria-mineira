module Admin
  # CRUD de Content::Page (seções 18-19 do PDF original) — inclui as páginas de
  # tipos de violência. IMPORTANTE: o PDF é explícito que os conceitos de tipos
  # de violência "serão fornecidos pela equipe" — esta tela só dá o meio de
  # cadastro, não valida nem gera esse conteúdo.
  class PagesController < Admin::BaseController
    before_action { require_role!("content_editor") }
    before_action :set_page, only: %i[ edit update destroy ]

    def index
      @pages = Content::Page.order(:content_type, :title)
    end

    def new
      @page = Content::Page.new
    end

    def create
      @page = Content::Page.new(page_params)
      if @page.save
        redirect_to admin_pages_path, notice: "Página criada."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @page.update(page_params)
        redirect_to admin_pages_path, notice: "Página atualizada."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @page.destroy
      redirect_to admin_pages_path, notice: "Página removida."
    end

    private

    def set_page
      @page = Content::Page.find_by!(slug: params[:id])
    end

    def page_params
      permitted = params.require(:content_page).permit(
        :content_type, :title, :slug, :summary, :body, :published,
        :taxonomy_tag_id, :show_find_service_cta, :show_chat_cta
      )
      published = permitted.delete(:published) == "1"
      permitted[:published_at] = published ? (@page&.published_at || Time.current) : nil
      permitted
    end
  end
end
