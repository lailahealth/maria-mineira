module Content
  # Controller genérico para seções de conteúdo que não precisam de estrutura
  # própria (diferente de tipos de violência — seção 19 do PDF original).
  class PagesController < ApplicationController
    SECTIONS = {
      "direitos" => { title: "Direitos", content_types: %w[direito] },
      "politicas-e-programas" => { title: "Políticas e programas", content_types: %w[politica programa] }
    }.freeze

    def index
      @section = SECTIONS.fetch(params[:section])
      @pages = Content::Page.where(content_type: @section[:content_types]).published.ordered
    end

    def show
      @section = SECTIONS.fetch(params[:section])
      @page = Content::Page.where(content_type: @section[:content_types]).published.find_by!(slug: params[:id])
      record_content_origin(@page)
    end
  end
end
