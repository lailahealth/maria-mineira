module Admin
  # Conta administrativa (área Admin::, não a usuária final — que nunca faz login,
  # ver ApplicationController). Papéis hipotéticos (seção 3.7/9 do parecer técnico):
  # o PDF não detalha perfis exatos, então esta é uma primeira divisão de
  # responsabilidades a validar com a equipe.
  class User < ApplicationRecord
    self.table_name = "admin_users"

    has_secure_password
    has_many :sessions, class_name: "Admin::Session", foreign_key: :admin_user_id, dependent: :destroy

    normalizes :email_address, with: ->(e) { e.strip.downcase }

    enum :role, {
      super_admin: 0,
      content_editor: 1,
      data_analyst: 2,
      partner_manager: 3
    }

    validates :role, presence: true
  end
end
