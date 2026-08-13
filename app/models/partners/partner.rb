module Partners
  # Rede Maria Mineira (seção 27 do PDF original). partner_type é texto livre
  # (mesmo padrão de Territorial::Facility#facility_type) porque o PDF não define
  # uma taxonomia fechada de tipos de parceiro — fica a cargo da equipe ao cadastrar.
  class Partner < ApplicationRecord
    self.table_name = "partners_partners"

    has_one_attached :logo

    validates :name, presence: true
    validates :partner_type, presence: true

    scope :active, -> { where(active: true) }
    scope :ordered, -> { order(:name) }
  end
end
