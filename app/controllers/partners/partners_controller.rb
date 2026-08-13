module Partners
  class PartnersController < ApplicationController
    def index
      @partners = Partners::Partner.active.ordered
    end
  end
end
