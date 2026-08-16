module AuthenticationHelpers
  # A factory de anunciante usa esta senha.
  def sign_in(user, password: "trilha123")
    post login_path, params: { email: user.email, password: password }
  end

  # Sessão de moderador é outra tabela e outro cookie.
  def sign_in_admin(admin, password: "trilha123")
    post admin_login_path, params: { email: admin.email, password: password }
  end
end

RSpec.configure do |config|
  config.include AuthenticationHelpers, type: :request
end
