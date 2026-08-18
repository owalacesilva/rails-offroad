class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[new create]

  before_action :redirect_if_authenticated, only: %i[new create]

  def new
  end

  def create
    # authenticate_by faz a comparação em tempo constante, o que não vaza
    # por timing se o e-mail existe ou não.
    user = User.authenticate_by(email: params[:email], password: params[:password])

    if user&.active?
      start_new_session_for user
      redirect_to after_authentication_url, notice: t(".success", name: user.name)
    else
      # A mensagem é a mesma da senha errada de propósito: dizer "sua conta
      # está bloqueada" para quem só chutou um e-mail revela que ele existe.
      flash.now[:alert] = t(".failure")
      render :new, status: :unprocessable_content
    end
  end

  def destroy
    terminate_session
    redirect_to root_path, notice: t(".success")
  end
end
