# Entrar com Google ou Facebook.
#
# O fluxo é o authorization code: `create` manda o navegador ao provedor,
# `callback` recebe o código de volta e o troca por um perfil (OauthProvider).
class OauthController < ApplicationController
  allow_unauthenticated_access

  before_action :redirect_if_authenticated
  before_action :load_provider

  # POST, e não GET, porque o botão precisa do token de CSRF: com um GET, um
  # site de terceiros consegue disparar o fluxo e deixar a vítima logada na
  # conta do atacante sem perceber.
  def create
    state = SecureRandom.urlsafe_base64(24)
    session[:oauth_state] = state

    redirect_to @provider.authorize_url(state: state, redirect_uri: callback_url),
                allow_other_host: true
  end

  def callback
    # O state é consumido antes de tudo, inclusive quando a pessoa desistiu no
    # provedor: deixá-lo na sessão o manteria válido para um retorno seguinte.
    expected = expected_state?

    return refuse(t(".denied")) if params[:error].present?

    profile = expected && @provider.profile(code: params[:code], redirect_uri: callback_url)

    profile ? enter(OauthAuthentication.new(profile)) : refuse(t(".failure"))
  end

  private
    def load_provider
      @provider = OauthProvider.find(params[:provider])

      # Provedor desconhecido ou sem credencial configurada: para quem está do
      # lado de fora, as duas coisas são a mesma — a rota não existe.
      raise ActionController::RoutingError, "Unknown provider" unless @provider
    end

    def callback_url
      oauth_callback_url(provider: @provider.key)
    end

    # O state é de uso único e vale só para a sessão que o gerou. Sem esta
    # checagem, um retorno forjado logaria a vítima na conta do atacante.
    def expected_state?
      sent = session.delete(:oauth_state).to_s
      received = params[:state].to_s

      sent.present? && ActiveSupport::SecurityUtils.secure_compare(sent, received)
    end

    def enter(authentication)
      user = authentication.user

      return start_registration(authentication.profile) unless user
      return refuse(t(".failure")) unless user.active?
      return refuse(t(".already_linked", provider: @provider.label)) unless authentication.connect(user)

      start_new_session_for user
      redirect_to after_authentication_url, notice: t(".success", name: user.name)
    end

    # Conta nova: o provedor deu nome e e-mail, mas o portal precisa de telefone,
    # cidade e UF. O perfil espera na sessão enquanto o formulário é preenchido.
    def start_registration(profile)
      session[:oauth] = profile.to_session

      redirect_to signup_path, notice: t(".complete", provider: @provider.label)
    end

    def refuse(message)
      session.delete(:oauth)

      redirect_to login_path, alert: message
    end
end
