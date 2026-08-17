class Proposal < ApplicationRecord
  belongs_to :ad
  # Nulo de propósito: proposta anônima continua valendo. Preenchido quando quem
  # envia está autenticado.
  belongs_to :user, optional: true

  validates :name, presence: true
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :offered_value, numericality: { greater_than: 0 }

  # Vírgula do formulário vira ponto antes do cast (ver ApplicationRecord).
  def offered_value=(value)
    super(self.class.normalize_decimal(value))
  end
end
