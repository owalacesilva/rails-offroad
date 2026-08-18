# Login por conta do Google ou do Facebook: fluxo de authorization code, feito à
# mão com Net::HTTP.
#
# Sem gem de OAuth porque o portal já escreve a própria autenticação (sessão em
# tabela, cookie assinado) em vez de usar Devise — e porque o fluxo, do lado do
# cliente confidencial, são duas chamadas HTTP: trocar o código por um token e
# perguntar quem é o dono do token.
#
# As credenciais vêm do ambiente, como os links do rodapé (lib/social_links.rb):
# provedor sem CLIENT_ID e CLIENT_SECRET definidos não existe para a aplicação —
# o botão não aparece no login e a rota devolve 404. É assim que uma instalação
# que só quer login por senha não mostra um botão que daria erro.
class OauthProvider
  # Conexão com provedor fora do ar não pode segurar um worker.
  TIMEOUT = 5

  PROVIDERS = {
    google: {
      label: "Google",
      id_variable: "GOOGLE_CLIENT_ID",
      secret_variable: "GOOGLE_CLIENT_SECRET",
      authorize_url: "https://accounts.google.com/o/oauth2/v2/auth",
      token_url: "https://oauth2.googleapis.com/token",
      profile_url: "https://openidconnect.googleapis.com/v1/userinfo",
      scope: "openid email profile"
    },
    facebook: {
      label: "Facebook",
      id_variable: "FACEBOOK_APP_ID",
      secret_variable: "FACEBOOK_APP_SECRET",
      authorize_url: "https://www.facebook.com/v21.0/dialog/oauth",
      token_url: "https://graph.facebook.com/v21.0/oauth/access_token",
      # O Graph só devolve o que for pedido em `fields`.
      profile_url: "https://graph.facebook.com/v21.0/me?fields=id,name,email",
      scope: "email"
    }
  }.freeze

  attr_reader :key

  # Ordem do hash é a ordem dos botões no formulário.
  def self.all(env = ENV)
    PROVIDERS.each_key.filter_map { |key| find(key, env) }
  end

  # nil para provedor desconhecido e para provedor sem credencial: quem chama
  # trata os dois do mesmo jeito, porque para o visitante são a mesma coisa.
  def self.find(key, env = ENV)
    name = key.to_s.downcase.to_sym
    settings = PROVIDERS[name]
    return unless settings

    credentials = settings.values_at(:id_variable, :secret_variable).map { |variable| env[variable].to_s.strip }

    new(name, settings, *credentials) if credentials.all?(&:present?)
  end

  def initialize(key, settings, client_id, client_secret)
    @key = key
    @settings = settings
    @client_id = client_id
    @client_secret = client_secret
  end

  def label
    @settings[:label]
  end

  # Para onde o navegador é mandado. `state` volta na chamada de retorno e é o
  # que prova que aquele retorno pertence a esta sessão.
  def authorize_url(state:, redirect_uri:)
    query = {
      client_id: @client_id, redirect_uri: redirect_uri, response_type: "code",
      scope: @settings[:scope], state: state
    }

    "#{@settings[:authorize_url]}?#{query.to_query}"
  end

  # Código de autorização em perfil, ou nil se qualquer etapa falhar. Falhar em
  # silêncio é de propósito: o visitante vê "não deu para entrar com o Google", e
  # a diferença entre código expirado, provedor fora do ar e e-mail não
  # verificado não é informação dele.
  def profile(code:, redirect_uri:)
    token = access_token(code, redirect_uri)

    token && OauthProfile.from_provider(key.to_s, get(@settings[:profile_url], token))
  end

  private
    def access_token(code, redirect_uri)
      body = post(@settings[:token_url],
                  client_id: @client_id, client_secret: @client_secret, code: code.to_s,
                  grant_type: "authorization_code", redirect_uri: redirect_uri)

      body && body["access_token"].presence
    end

    def post(url, **form)
      uri = URI(url)
      request = Net::HTTP::Post.new(uri)
      request.set_form_data(form)

      parse(perform(uri, request))
    end

    def get(url, token)
      uri = URI(url)
      request = Net::HTTP::Get.new(uri)
      request["Authorization"] = "Bearer #{token}"

      parse(perform(uri, request))
    end

    def perform(uri, request)
      Net::HTTP.start(uri.host, uri.port, use_ssl: true,
                      open_timeout: TIMEOUT, read_timeout: TIMEOUT) do |http|
        http.request(request)
      end
    rescue StandardError
      nil
    end

    def parse(response)
      return unless response.is_a?(Net::HTTPSuccess)

      JSON.parse(response.body)
    rescue JSON::ParserError
      nil
    end
end
