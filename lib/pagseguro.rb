# Cobrança do plano Premium no PagBank (PagSeguro), feita à mão com Net::HTTP —
# mesma decisão de lib/oauth_provider.rb: sem gem, porque a integração são duas
# conversas curtas (criar o checkout, receber a notificação) e o projeto prefere
# escrever um objeto pequeno a carregar uma dependência.
#
# É o Checkout **hospedado**, não o transparente: quem paga sai do portal, digita
# o cartão no PagBank e volta. Isso evita três coisas de uma vez — nenhum dado de
# cartão passa por aqui, nenhum script de terceiro entra na página (o que a
# Política de Privacidade promete) e nenhuma coluna de CPF ou endereço precisa
# entrar em `users`, porque a página do PagBank pede o que ela precisa. É também
# por isso que o corpo enviado **não** leva o objeto `customer`: a API exige
# `tax_id` junto com o nome quando ele vem, e o portal não guarda CPF.
#
# As credenciais vêm do ambiente, como os links do rodapé e os provedores de
# login: sem PAGSEGURO_TOKEN a assinatura não existe — o botão do Premium volta a
# ser o e-mail de contato e as rotas devolvem 404. Uma instalação que só quer
# classificado de graça não mostra um botão que daria erro.
class Pagseguro
  # Gateway fora do ar não pode segurar um worker. Um pouco mais folgado que o do
  # OauthProvider: aqui a resposta é a criação de uma cobrança.
  TIMEOUT = 8

  # Sandbox é o padrão de propósito, e qualquer valor fora do mapa também cai
  # nele: errar a grafia de "production" tem de custar uma cobrança que não
  # acontece, nunca uma que acontece sem querer.
  HOSTS = {
    "sandbox" => "https://sandbox.api.pagseguro.com",
    "production" => "https://api.pagseguro.com"
  }.freeze

  # Prazo do link de pagamento: um dia é bastante para quem foi buscar o cartão,
  # e não deixa link de cobrança de pé por semanas.
  EXPIRATION = 1.day

  # Para onde é aceitável mandar o navegador. O endereço vem da resposta do
  # PagBank, que é confiável, mas é ele que vira um redirect para fora do portal:
  # exigir https recusa de saída um "javascript:" ou "data:" que aparecesse ali,
  # sem prender o portal a um domínio de pagamento que não é nosso e pode mudar.
  # Mesma ideia de Event::HTTP_URL antes de a home virar um href — só que aqui,
  # tratando-se de pagamento, http puro também não serve.
  PAY_URL = %r{\Ahttps://}i

  # A cobrança a ser criada. É Data com comportamento, e não meia dúzia de
  # parâmetros, porque o formato do corpo que o PagBank espera é assunto dela —
  # e porque assim o cliente HTTP não precisa conhecer nada do plano.
  Order = Data.define(:reference_id, :amount_cents, :item_name, :redirect_url, :notification_url) do
    def payload
      {
        reference_id: reference_id,
        # Um item, quantidade um: o plano é uma mensalidade, não um carrinho.
        items: [ { name: item_name, quantity: 1, unit_amount: amount_cents } ],
        expiration_date: EXPIRATION.from_now.iso8601,
        # O retorno é a experiência de quem pagou; a notificação é a única coisa
        # em que a aplicação confia para conceder o Premium.
        redirect_url: redirect_url,
        notification_urls: [ notification_url ],
        # Aparece na fatura do cartão. A API limita a 17 caracteres.
        soft_descriptor: "OffRoadClass"
      }
    end
  end

  # nil quando não há token: quem chama trata credencial ausente do mesmo jeito
  # que OauthProvider.find trata provedor desconhecido.
  def self.build(env = ENV)
    token = env["PAGSEGURO_TOKEN"].to_s.strip

    new(token, env["PAGSEGURO_ENV"]) if token.present?
  end

  def self.configured?(env = ENV)
    build(env).present?
  end

  def initialize(token, environment = nil)
    @token = token
    @host = HOSTS.fetch(environment.to_s.strip.downcase, HOSTS.fetch("sandbox"))
  end

  # Cria a cobrança e devolve o endereço para onde mandar o navegador, ou nil se
  # qualquer etapa falhar. Falhar em silêncio é de propósito, como no login por
  # provedor: quem anuncia vê "não deu para abrir o pagamento", e a diferença
  # entre token inválido, PagBank fora do ar e resposta sem link não é
  # informação dele.
  def create_checkout(order)
    body = post("#{@host}/checkouts", order.payload)

    pay_url(body)
  end

  # A notificação é de verdade? O PagBank assina o corpo com o próprio token:
  # SHA256("#{token}-#{corpo}") no cabeçalho x-authenticity-token.
  #
  # O corpo tem de ser o texto cru recebido (request.raw_post) — reserializar o
  # JSON muda um espaço e o hash deixa de bater. Sem esta conferência, quem
  # descobrisse a URL concederia Premium a si mesmo com um POST.
  def authentic?(payload, signature)
    received = signature.to_s

    received.present? && ActiveSupport::SecurityUtils.secure_compare(digest(payload), received)
  end

  private
    def digest(payload)
      OpenSSL::Digest::SHA256.hexdigest("#{@token}-#{payload}")
    end

    # O link de pagamento vem entre os `links`, marcado com rel PAY.
    def pay_url(body)
      href = Array(body&.dig("links")).find { |link| link["rel"] == "PAY" }&.dig("href")

      href if href&.match?(PAY_URL)
    end

    def post(url, payload)
      uri = URI(url)
      request = Net::HTTP::Post.new(uri)
      request["Authorization"] = "Bearer #{@token}"
      request["Content-Type"] = "application/json"
      request["Accept"] = "application/json"
      request.body = payload.to_json

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
