module Taxonomy
  # Taxonomia hierárquica (tag/subtag) usada para tag_origem, tag_motivo e tag_chat
  # (seções 5-7 do parecer técnico). Administrada, no futuro, pela equipe Maria Mineira —
  # os valores aqui são um rascunho inicial, não a taxonomia definitiva.
  class Tag < ApplicationRecord
    self.table_name = "taxonomy_tags"

    enum :kind, { general: 0, violence_type: 1 }, default: :general

    belongs_to :parent, class_name: "Taxonomy::Tag", optional: true
    has_many :children, class_name: "Taxonomy::Tag", foreign_key: :parent_id, dependent: :nullify

    validates :slug, presence: true, uniqueness: true
    validates :label, presence: true

    scope :active, -> { where(active: true) }
    scope :roots, -> { where(parent_id: nil) }

    def to_param
      slug
    end
  end
end
