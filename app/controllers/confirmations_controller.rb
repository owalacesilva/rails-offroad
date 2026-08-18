# Confirmação de e-mail do cadastro.
#
# Não há coluna de token: `User.generates_token_for` assina o id junto com o
# e-mail e o prazo, então o link se invalida sozinho e trocar de e-mail derruba
# um link que ainda estivesse na caixa de entrada do endereço antigo.
class ConfirmationsController < ApplicationController
  allow_unauthenticated_access

  # O link do e-mail.
  def show
    user = User.find_by_token_for(:email_confirmation, params[:token])

    return redirect_to new_email_confirmation_path, alert: t(".invalid") unless user

    user.confirm_email
    redirect_to login_path, notice: t(".success")
  end

  # Reenvio, para quem perdeu o e-mail ou deixou o prazo passar.
  def new
    @email = params[:email]
  end

  def create
    user = User.find_by(email: params[:email].to_s.strip.downcase)
    UserMailer.confirmation(user).deliver_later if user && !user.confirmed?

    # A resposta é a mesma exista ou não a conta. Dizer "não encontrei esse
    # e-mail" transformaria o formulário num verificador de quem é cadastrado.
    redirect_to login_path, notice: t(".sent")
  end
end
