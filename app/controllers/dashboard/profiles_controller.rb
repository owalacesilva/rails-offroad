module Dashboard
  class ProfilesController < ApplicationController
    def edit
      @advertiser = current_advertiser
    end

    def update
      @advertiser = current_advertiser

      if @advertiser.update(profile_params)
        redirect_to account_path, notice: t(".success")
      else
        render :edit, status: :unprocessable_content
      end
    end

    private
      # Senha só entra na atualização se o anunciante preencheu um valor novo.
      def profile_params
        permitted = params.expect(advertiser: [ :name, :email, :phone, :city, :state, :password, :password_confirmation ])
        permitted[:password].present? ? permitted : permitted.except(:password, :password_confirmation)
      end
  end
end
