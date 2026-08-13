module Content
  class ViolenceTypesController < ApplicationController
    def index
      @pages = Content::Page.tipo_violencia.published.ordered
    end

    def show
      @page = Content::Page.tipo_violencia.published.find_by!(slug: params[:id])
      record_content_origin(@page)
    end
  end
end
