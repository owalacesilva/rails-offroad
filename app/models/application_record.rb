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

  # O que o leitor de um campo de dinheiro devolve: reais quando a conversão deu
  # certo, e o texto cru quando não deu. É o que o `_before_type_cast` fazia
  # quando a coluna era DECIMAL — sem isso, o formulário que volta com erro
  # apagaria o que a pessoa digitou.
  def self.amount_or_input(cents, input)
    cents ? to_amount(cents) : input.presence
  end
end
