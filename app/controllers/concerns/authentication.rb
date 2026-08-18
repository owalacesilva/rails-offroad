# Sessão em tabela, com o id guardado em cookie assinado. Mesmo desenho do
# gerador de autenticação do Rails 8, aplicado ao User.
#
# O padrão é negar: toda controller exige sessão, e quem for público declara
# `allow_unauthenticated_access`. Controller nova nasce protegida.
module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :require_authentication
    helper_method :authenticated?, :current_user
  end

  class_methods do
    def allow_unauthenticated_access(**options)
      skip_before_action :require_authentication, **options
    end
  end

  private
    def authenticated?
      resume_session.present?
    end

    def current_user
      Current.user
    end

    def require_authentication
      resume_session || request_authentication
    end

    def resume_session
      Current.session ||= find_session_by_cookie
    end

    # Só sessão de anunciante ativo e com e-mail confirmado é retomada: bloquear
    # alguém tem de valer para quem já estava logado, não só no próximo login, e
    # o mesmo vale para uma confirmação que deixe de valer.
    def find_session_by_cookie
      Session.joins(:user).merge(User.active.confirmed).find_by(id: cookies.signed[:session_id])
    end

    # Quem já tem sessão não precisa ver login nem cadastro.
    def redirect_if_authenticated
      redirect_to root_path, notice: t("sessions.already_authenticated") if authenticated?
    end

    def request_authentication
      session[:return_to_after_authenticating] = request.url
      redirect_to login_path, alert: t("sessions.required")
    end

    def after_authentication_url
      session.delete(:return_to_after_authenticating) || root_url
    end

    def start_new_session_for(user)
      user.sessions.create!(user_agent: request.user_agent, ip_address: request.remote_ip).tap do |record|
        Current.session = record
        # secure em produção independe de config.force_ssl, que vem comentado no
        # production.rb do Rails — o cookie é credencial e não pode trafegar limpo.
        cookies.signed.permanent[:session_id] = {
          value: record.id, httponly: true, same_site: :lax, secure: Rails.env.production?
        }
      end
    end

    def terminate_session
      resume_session&.destroy
      Current.session = nil
      cookies.delete(:session_id)
    end
end
