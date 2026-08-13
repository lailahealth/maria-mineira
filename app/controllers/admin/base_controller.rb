module Admin
  # Toda área administrativa exige login (Authentication#require_authentication,
  # incluído aqui e não em ApplicationController — a usuária final nunca loga,
  # ver comentário em ApplicationController).
  class BaseController < ApplicationController
    include Authentication
    layout "admin"

    helper_method :current_admin_user

    private

    def current_admin_user
      Current.user
    end

    # Autorização simples por papel (seção 3.7/9 do parecer técnico — papéis
    # hipotéticos, a validar com a equipe). Sem Pundit/Action Policy: 4 papéis
    # fixos não justificam uma gem de policy neste protótipo. super_admin
    # sempre passa; os demais controllers chamam isto com os papéis permitidos.
    def require_role!(*roles)
      return if current_admin_user.super_admin? || roles.map(&:to_s).include?(current_admin_user.role)

      redirect_to admin_root_path, alert: "Você não tem permissão para acessar esta área."
    end
  end
end
