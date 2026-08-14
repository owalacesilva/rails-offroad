class RegistrationsController < ApplicationController
  allow_unauthenticated_access

  before_action :redirect_if_authenticated

  def new
    @advertiser = Advertiser.new
  end

  def create
    @advertiser = Advertiser.new(registration_params)
    @advertiser.member_since = Date.current

    if @advertiser.save
      start_new_session_for @advertiser
      redirect_to root_path, notice: t(".success", name: @advertiser.name)
    else
      render :new, status: :unprocessable_content
    end
  end

  private
    def registration_params
      params.expect(advertiser: [ :name, :email, :phone, :city, :state, :password, :password_confirmation ])
    end
end
