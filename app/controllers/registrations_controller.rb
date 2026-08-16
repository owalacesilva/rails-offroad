class RegistrationsController < ApplicationController
  allow_unauthenticated_access

  before_action :redirect_if_authenticated

  def new
    @user = User.new
  end

  def create
    @user = User.new(registration_params)
    @user.member_since = Date.current

    if @user.save
      start_new_session_for @user
      redirect_to root_path, notice: t(".success", name: @user.name)
    else
      render :new, status: :unprocessable_content
    end
  end

  private
    def registration_params
      params.expect(user: [ :name, :email, :phone, :city, :state, :password, :password_confirmation ])
    end
end
