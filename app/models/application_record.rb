class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  # Dinheiro é guardado em centavos inteiros (`*_cents`), e a aplicação continua
  # falando em reais. Estes dois métodos são a fronteira entre as duas unidades;
  # quem os usa é o par de acessores em Ad e Proposal.
  CENTS_PER_UNIT = 100

  # O formulário trabalha em reais; a coluna guarda centavos. Vive aqui porque
  # preço de anúncio e valor de proposta precisam do mesmo tratamento.
  #
  # Havendo vírgula, ela é o separador decimal e o ponto só pode ser separador
  # de milhar: "45.000,50" vira "45000.50". Sem vírgula o ponto é preservado,
  # porque aí é ele o decimal ("45000.50", teclado en-US).
  def self.normalize_decimal(value)
    return value unless value.is_a?(String)

    text = value.strip
    text.include?(",") ? text.delete(".").tr(",", ".") : text
  end

  # Reais -> centavos. Devolve nil para entrada vazia ou que não é número, e é
  # a validação de numericalidade do modelo que reclama disso.
  def self.to_cents(value)
    return if value.blank?

    amount = BigDecimal(normalize_decimal(value).to_s, exception: false)

    (amount * CENTS_PER_UNIT).round if amount
  end

  # Centavos -> reais, em BigDecimal para não haver arredondamento de float no
  # caminho até o number_to_currency.
  def self.to_amount(cents)
    BigDecimal(cents) / CENTS_PER_UNIT if cents
  end

  # Endereço externo aceito nos campos de URL do portal. Só http(s): um
  # "javascript:..." ou um "data:..." gravado direto no banco viraria link
  # clicável — ou imagem — numa página pública.
  HTTP_URL = %r{\Ahttps?://\S+\z}i

  # Versões de instância dos dois auxiliares de imagem abaixo, para os leitores
  # de capa não repetirem `self.class` a cada linha.
  delegate :attachment_path, :http_url, to: :class

  # Caminho de exibição de um anexo do Active Storage.
  #
  # Rota de proxy, e não URL assinada direta do MinIO: dentro da rede do Compose
  # o endpoint é http://minio:9000, que o navegador do host não resolve. E
  # only_path porque isto também roda fora de uma requisição (console, job), onde
  # a rota direta tentaria montar URL absoluta e estouraria por falta de host.
  def self.attachment_path(attachment)
    Rails.application.routes.url_helpers.rails_storage_proxy_path(attachment, only_path: true)
  end

  # Segunda barreira, para a view não depender de a linha ter passado pela
  # validação: vale também para o que foi gravado por SQL direto.
  def self.http_url(value)
    value if value.to_s.match?(%r{\Ahttps?://}i)
  end

  # O que um campo de texto rico pode conter: exatamente os cinco controles do
  # editor do formulário (negrito, itálico, as duas listas e H3) mais os blocos
  # que eles produzem. Nenhum atributo passa — nem style, nem class, nem href.
  # Vale para a descrição do anúncio e para o corpo do post do blog.
  RICH_TEXT_TAGS = %w[p br strong em b i ul ol li h3].freeze

  # Limpeza na entrada, não na exibição: assim o banco só guarda o que já está
  # dentro da lista. Texto puro atravessa sem virar HTML.
  def self.sanitize_rich_text(value)
    return value if value.blank?

    Rails::HTML5::SafeListSanitizer.new.sanitize(value.to_s, tags: RICH_TEXT_TAGS, attributes: [])
  end

  # Slug livre a partir de uma base, com sufixo numérico quando já existe.
  # Corrida entre dois INSERTs simultâneos ainda esbarra no índice único — que
  # é justamente quem garante a unicidade de verdade.
  def self.unique_slug(base)
    return base unless exists?(slug: base)

    suffix = 2
    suffix += 1 while exists?(slug: "#{base}-#{suffix}")

    "#{base}-#{suffix}"
  end

  # O que o leitor de um campo de dinheiro devolve: reais quando a conversão deu
  # certo, e o texto cru quando não deu. É o que o `_before_type_cast` fazia
  # quando a coluna era DECIMAL — sem isso, o formulário que volta com erro
  # apagaria o que a pessoa digitou.
  def self.amount_or_input(cents, input)
    cents ? to_amount(cents) : input.presence
  end
end
