module Admin
  class PasswordsMailer < ApplicationMailer
    def reset(user)
      @user = user
      mail subject: "Redefinição de senha — Maria Mineira", to: user.email_address
    end
  end
end
