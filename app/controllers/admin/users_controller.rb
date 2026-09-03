module Admin
  # Gestão de contas administrativas — restrita a super_admin. Autocadastro não
  # existe de propósito: contas só são criadas por quem já tem acesso.
  class UsersController < Admin::BaseController
    before_action { require_role!("super_admin") }
    before_action :set_user, only: %i[ edit update destroy ]

    def index
      @pagy, @users = pagy(Admin::User.order(:email_address))
    end

    def new
      @user = Admin::User.new
    end

    def create
      @user = Admin::User.new(user_params)
      if @user.save
        redirect_to admin_users_path, notice: "Administradora criada."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      attrs = user_params
      attrs = attrs.except(:password, :password_confirmation) if attrs[:password].blank?

      if @user.update(attrs)
        redirect_to admin_users_path, notice: "Administradora atualizada."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      if @user == current_admin_user
        redirect_to admin_users_path, alert: "Você não pode remover sua própria conta."
        return
      end

      @user.destroy
      redirect_to admin_users_path, notice: "Administradora removida."
    end

    private

    def set_user
      @user = Admin::User.find(params[:id])
    end

    def user_params
      params.require(:admin_user).permit(:email_address, :role, :password, :password_confirmation)
    end
  end
end
