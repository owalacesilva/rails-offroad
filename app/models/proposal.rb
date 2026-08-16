class Proposal < ApplicationRecord
  belongs_to :ad
  # Nulo de propósito: proposta anônima continua valendo. Preenchido quando quem
  # envia está autenticado.
  belongs_to :user, optional: true

  validates :name, presence: true
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :offered_value, numericality: { greater_than: 0 }

  # O formulário trabalha em reais com vírgula; a coluna é DECIMAL com ponto.
  def offered_value=(value)
    super(self.class.normalize_decimal(value))
  end

  def self.normalize_decimal(value)
    value.is_a?(String) ? value.strip.tr(",", ".") : value
  end
end
