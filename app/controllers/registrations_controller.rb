class RegistrationsController < ApplicationController
  REGISTRATION_FIELDS = %i[name email phone city state password password_confirmation].freeze

  # No cadastro por provedor estes três não vêm do formulário: o e-mail é o que
  # o Google ou o Facebook confirmou, e senha essa pessoa não tem.
  PROVIDER_MANAGED = %i[email password password_confirmation].freeze

  allow_unauthenticated_access

  before_action :redirect_if_authenticated
  before_action :abandon_oauth, only: :new
  before_action :load_pending_oauth

  def new
    @user = User.new(name: @oauth&.name, email: @oauth&.email)
  end

  def create
    @user = build_user

    return render :new, status: :unprocessable_content unless @user.save

    @oauth ? finish_oauth_signup : finish_email_signup
  end

  private
    # Saída para quem começou pelo provedor e mudou de ideia. Sem ela o
    # formulário fica preso no modo do provedor até o navegador fechar, já que o
    # perfil pendente vive na sessão.
    def abandon_oauth
      return if params[:oauth].blank?

      session.delete(:oauth)
      redirect_to signup_path
    end

    def load_pending_oauth
      @oauth = OauthProfile.from_session(session[:oauth])
    end

    def build_user
      user = User.new(user_attributes)
      user.member_since = Date.current
      user
    end

    def user_attributes
      return registration_params unless @oauth

      # O e-mail sai da sessão e não do formulário: aceitar o que veio no POST
      # deixaria alguém entrar com o Google de um endereço e sair cadastrado,
      # já confirmado, com o endereço de outra pessoa.
      registration_params.except(*PROVIDER_MANAGED)
                         .merge(email: @oauth.email, password: User.random_password,
                                confirmed_at: Time.current)
    end

    def finish_oauth_signup
      @user.oauth_identities.create!(provider: @oauth.provider, uid: @oauth.uid)
      session.delete(:oauth)

      start_new_session_for @user
      redirect_to root_path, notice: t(".success", name: @user.name)
    end

    # Sem sessão: quem se cadastra por e-mail entra depois de confirmar. É a
    # confirmação que separa "digitou um endereço" de "tem esse endereço".
    def finish_email_signup
      UserMailer.confirmation(@user).deliver_later

      redirect_to login_path, notice: t(".confirmation_sent", email: @user.email)
    end

    def registration_params
      params.expect(user: REGISTRATION_FIELDS)
    end
end
