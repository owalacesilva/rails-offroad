class Proposal < ApplicationRecord
  belongs_to :ad
  # Nulo de propósito: proposta anônima continua valendo. Preenchido quando quem
  # envia está autenticado.
  belongs_to :user, optional: true

  validates :name, presence: true
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  # A validação fica no leitor em reais, e não em offered_value_cents, para a
  # mensagem de erro falar a língua do formulário.
  validates :offered_value, numericality: { greater_than: 0 }

  # A coluna é offered_value_cents (inteiro); a aplicação fala em reais.
  def offered_value
    self.class.amount_or_input(offered_value_cents, @offered_value_input)
  end

  def offered_value=(value)
    @offered_value_input = value
    self.offered_value_cents = self.class.to_cents(value)
  end
end
