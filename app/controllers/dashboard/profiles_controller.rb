module Dashboard
  class ProfilesController < BaseController
    PROFILE_FIELDS = %i[name email phone city state password password_confirmation].freeze
    PASSWORD_FIELDS = %i[password password_confirmation].freeze

    def edit
      @user = current_user
    end

    def update
      @user = current_user

      if @user.update(profile_params)
        # Chave explícita: a controller vive em Dashboard::, então o lookup
        # preguiçoso procuraria dashboard.profiles.update.success.
        redirect_to account_path, notice: t("profiles.update.success")
      else
        render :edit, status: :unprocessable_content
      end
    end

    private
      # Senha só entra na atualização se o usuário preencheu um valor novo.
      def profile_params
        changing_password? ? permitted_params : permitted_params.except(*PASSWORD_FIELDS)
      end

      def changing_password?
        permitted_params[:password].present?
      end

      def permitted_params
        @permitted_params ||= params.expect(user: PROFILE_FIELDS)
      end
  end
end
