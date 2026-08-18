# O que o provedor contou sobre a pessoa, já normalizado: só o que o portal usa.
#
# Nada de token aqui. O access_token serve para uma chamada, dentro da mesma
# requisição, e morre com ela — o portal não age em nome de ninguém no Google
# nem no Facebook depois disso.
#
# Vira e volta da sessão porque o cadastro por provedor tem duas etapas: o
# Google diz nome e e-mail, mas telefone, cidade e UF só a pessoa sabe, e são
# obrigatórios num portal de classificados.
OauthProfile = Data.define(:provider, :uid, :email, :name) do
  # Resposta crua do provedor em perfil, ou nil se ela não serve.
  #
  # Google devolve `sub`, Facebook devolve `id`; os dois devolvem `name` e
  # `email`. E-mail é o único campo de que o portal não abre mão: é a chave que
  # liga a conta do provedor à conta daqui.
  def self.from_provider(provider, data)
    return if data.blank?

    email = data["email"].to_s.strip.downcase
    uid = (data["sub"] || data["id"]).to_s

    return unless uid.present? && email.present? && verified?(data)

    new(provider: provider, uid: uid, email: email, name: data["name"].to_s.strip)
  end

  # O Google diz explicitamente se o endereço foi verificado. O Facebook não
  # manda o campo: ele só devolve `email` de conta cujo endereço já confirmou, e
  # omitir é o jeito dele de dizer que não tem endereço confiável.
  #
  # A checagem é o que impede alguém de abrir uma conta no provedor com o e-mail
  # de outra pessoa e entrar no lugar dela aqui.
  def self.verified?(data)
    data.fetch("email_verified", true).present?
  end

  # A sessão é cookie assinado e serializado em JSON: chave símbolo volta string.
  def self.from_session(data)
    return if data.blank?

    new(**data.symbolize_keys.slice(*members))
  rescue ArgumentError
    # Cookie de uma versão anterior, com outro conjunto de campos: trata-se como
    # cadastro nenhum em andamento, e não como erro na cara do usuário.
    nil
  end

  def to_session
    to_h
  end
end
