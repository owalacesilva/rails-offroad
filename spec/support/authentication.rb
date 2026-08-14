module AuthenticationHelpers
  # A factory de anunciante usa esta senha.
  def sign_in(advertiser, password: "trilha123")
    post login_path, params: { email: advertiser.email, password: password }
  end
end

RSpec.configure do |config|
  config.include AuthenticationHelpers, type: :request
end
