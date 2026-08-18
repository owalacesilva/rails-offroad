# Credenciais de provedor no ambiente do exemplo.
#
# lib/oauth_provider.rb lê o ENV porque é assim que a instalação configura os
# provedores — e sem credencial o botão não existe. Marque o exemplo com `:oauth`
# para que ele rode com Google e Facebook configurados.
module OauthEnvironment
  CREDENTIALS = {
    "GOOGLE_CLIENT_ID" => "client-de-teste.apps.googleusercontent.com",
    "GOOGLE_CLIENT_SECRET" => "segredo-do-google",
    "FACEBOOK_APP_ID" => "1234567890",
    "FACEBOOK_APP_SECRET" => "segredo-do-facebook"
  }.freeze
end

RSpec.configure do |config|
  config.around(:each, :oauth) do |example|
    previous = OauthEnvironment::CREDENTIALS.keys.index_with { |name| ENV[name] }
    ENV.update(OauthEnvironment::CREDENTIALS)

    example.run
  ensure
    previous.each { |name, value| value.nil? ? ENV.delete(name) : ENV[name] = value }
  end
end
