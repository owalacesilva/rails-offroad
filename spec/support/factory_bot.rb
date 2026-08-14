# Permite chamar build/create direto no exemplo, sem o prefixo FactoryBot.
RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods
end
