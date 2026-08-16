module Moderation
  class SessionsController < BaseController
    allow_unauthenticated_admin_access only: %i[new create]

    def new
    end

    def create
      admin = Admin.authenticate_by(email: params[:email], password: params[:password])

      if admin
        start_new_admin_session_for admin
        redirect_to admin_root_path, notice: t("admin.sessions.create.success", name: admin.name)
      else
        flash.now[:alert] = t("admin.sessions.create.failure")
        render :new, status: :unprocessable_content
      end
    end

    def destroy
      terminate_admin_session
      redirect_to admin_login_path, notice: t("admin.sessions.destroy.success")
    end
  end
end
