# Credencial do PagBank no ambiente do exemplo.
#
# lib/pagseguro.rb lê o ENV porque é assim que a instalação configura o gateway —
# e sem token a assinatura não existe: a rota devolve 404 e o botão do Premium
# volta a ser o e-mail de contato. Marque o exemplo com `:pagseguro` para que ele
# rode com o gateway configurado (em sandbox).
module PagseguroEnvironment
  TOKEN = "token-de-teste-do-pagbank".freeze

  CREDENTIALS = { "PAGSEGURO_TOKEN" => TOKEN, "PAGSEGURO_ENV" => "sandbox" }.freeze

  # A assinatura que o PagBank põe no cabeçalho: SHA256 do token com o corpo cru.
  def self.signature(payload, token: TOKEN)
    OpenSSL::Digest::SHA256.hexdigest("#{token}-#{payload}")
  end
end

RSpec.configure do |config|
  config.around(:each, :pagseguro) do |example|
    previous = PagseguroEnvironment::CREDENTIALS.keys.index_with { |name| ENV[name] }
    ENV.update(PagseguroEnvironment::CREDENTIALS)

    example.run
  ensure
    previous.each { |name, value| value.nil? ? ENV.delete(name) : ENV[name] = value }
  end
end
