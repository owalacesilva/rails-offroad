class Proposal < ApplicationRecord
  belongs_to :listing

  validates :name, presence: true
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :amount_cents, numericality: { only_integer: true, greater_than: 0 }

  # O formulário trabalha em reais, o banco em centavos. O valor cru é guardado
  # para o campo não esvaziar quando a validação falha.
  def amount
    @amount || (amount_cents && BigDecimal(amount_cents) / 100)
  end

  def amount=(value)
    @amount = value
    normalized = value.to_s.strip.tr(",", ".")
    self.amount_cents = normalized.blank? ? nil : (BigDecimal(normalized) * 100).to_i
  rescue ArgumentError
    # Valor não numérico zera os centavos e a validação reclama.
    self.amount_cents = nil
  end
end
