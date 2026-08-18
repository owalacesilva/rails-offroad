class UserMailer < ApplicationMailer
  # O token é gerado na hora do envio, não guardado em coluna: quem o assina é
  # o Rails (User.generates_token_for), com prazo e com o e-mail dentro.
  def confirmation(user)
    @user = user
    @url = email_confirmation_url(token: user.generate_token_for(:email_confirmation))
    @hours = (User::CONFIRMATION_WINDOW / 1.hour).to_i

    mail(to: user.email, subject: t("user_mailer.confirmation.subject"))
  end
end
