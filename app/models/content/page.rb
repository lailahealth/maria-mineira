module Content
  # Conteúdo educativo (seções 18-19 do PDF original): um único model com
  # `content_type` cobre tipos de violência, direitos, políticas, programas etc.
  # A página de "tipo de violência" é só um content_type com CTAs obrigatórios.
  class Page < ApplicationRecord
    self.table_name = "content_pages"

    enum :content_type, {
      tipo_violencia: 0,
      direito: 1,
      politica: 2,
      programa: 3,
      servico_info: 4,
      campanha: 5,
      informacao_util: 6
    }

    belongs_to :taxonomy_tag, class_name: "Taxonomy::Tag", optional: true

    validates :title, presence: true
    validates :slug, presence: true, uniqueness: true

    scope :published, -> { where.not(published_at: nil).where("published_at <= ?", Time.current) }
    scope :ordered, -> { order(:title) }

    def to_param
      slug
    end
  end
end
