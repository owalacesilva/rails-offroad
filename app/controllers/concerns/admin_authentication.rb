# Autenticação de moderador, deliberadamente paralela à do anunciante: outra
# tabela, outro cookie, outra concern. Nada aqui toca em Authentication, então
# mudar a moderação não arrisca o login do portal.
module AdminAuthentication
  extend ActiveSupport::Concern

  ADMIN_COOKIE = :admin_session_id

  included do
    before_action :require_admin
    helper_method :admin_authenticated?, :current_admin
  end

  class_methods do
    def allow_unauthenticated_admin_access(**options)
      skip_before_action :require_admin, **options
    end
  end

  private
    def admin_authenticated?
      resume_admin_session.present?
    end

    def current_admin
      Current.admin
    end

    def require_admin
      resume_admin_session || request_admin_authentication
    end

    def resume_admin_session
      Current.admin_session ||= AdminSession.find_by(id: cookies.signed[ADMIN_COOKIE])
    end

    def request_admin_authentication
      redirect_to admin_login_path, alert: t("admin.sessions.required")
    end

    def start_new_admin_session_for(admin)
      admin.admin_sessions.create!(user_agent: request.user_agent, ip_address: request.remote_ip).tap do |record|
        Current.admin_session = record
        cookies.signed.permanent[ADMIN_COOKIE] = {
          value: record.id, httponly: true, same_site: :lax, secure: Rails.env.production?
        }
      end
    end

    def terminate_admin_session
      resume_admin_session&.destroy
      Current.admin_session = nil
      cookies.delete(ADMIN_COOKIE)
    end
end
