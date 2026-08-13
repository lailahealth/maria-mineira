module Admin
  class Session < ApplicationRecord
    self.table_name = "admin_sessions"

    belongs_to :user, class_name: "Admin::User", foreign_key: :admin_user_id
  end
end
