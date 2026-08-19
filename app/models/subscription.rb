# Uma cobrança do plano Premium. Nasce `pending` quando o anunciante manda criar
# o checkout e vira `paid` quando a notificação do PagBank confirma o pagamento.
#
# Cada linha é um mês pago. Não há renovação automática: o checkout hospedado
# cobra uma vez, e um mês novo é uma linha nova — o que também é o que faz
# `paid_through` se acumular em vez de ser sobrescrito.
class Subscription < ApplicationRecord
  # Quanto tempo de Premium um pagamento confirmado concede.
  PERIOD = 1.month

  STATUSES = { pending: "pending", paid: "paid", declined: "declined", canceled: "canceled" }.freeze

  # Situação da cobrança no PagBank -> situação daqui. O que não estiver no mapa
  # (AUTHORIZED, WAITING, IN_ANALYSIS) deixa a linha como está: ainda não é
  # desfecho, e sobrescrever com "pending" apagaria um pagamento já confirmado
  # se as notificações chegarem fora de ordem.
  GATEWAY_STATUSES = { "PAID" => :paid, "DECLINED" => :declined, "CANCELED" => :canceled }.freeze

  belongs_to :user

  enum :status, STATUSES

  validates :gateway_reference, presence: true, uniqueness: { case_sensitive: false }
  validates :amount_cents, numericality: { only_integer: true, greater_than: 0 }

  # Vale hoje: pago e dentro do prazo. A data é comparada no banco para a
  # pergunta caber num índice (user_id, paid_through).
  scope :current, ->(today = Date.current) { paid.where(paid_through: today..) }

  # Reais, como todo valor que a aplicação mostra (ver ApplicationRecord).
  def amount
    self.class.to_amount(amount_cents)
  end

  # Cobrança recém-aberta, ainda sem checkout no PagBank. A referência é sorteada
  # e não derivada do id: ela viaja para fora do portal e volta numa requisição
  # pública, então não convém que seja adivinhável em sequência.
  def self.open_for(user, amount_cents:)
    create!(user: user, amount_cents: amount_cents,
            gateway_reference: "PREMIUM-#{SecureRandom.hex(12)}")
  end

  # Aplica o que o PagBank disse. Devolve false para situação que não é desfecho,
  # para quem chama saber que não houve mudança.
  def apply_gateway_status(gateway_status, at: Time.current)
    outcome = GATEWAY_STATUSES[gateway_status.to_s.upcase]
    return false unless outcome

    outcome == :paid ? confirm_payment(at) : update!(status: outcome)
  end

  private
    # Idempotente de propósito: cliente de e-mail não é o único que repete
    # requisição — webhook também é reenviado, e um segundo POST não pode
    # conceder um segundo mês. `paid_at` é o que registra que já foi contado.
    #
    # O prazo novo parte do fim do Premium que o anunciante já tinha, e não de
    # hoje: quem renova antes de vencer não perde os dias que faltavam.
    def confirm_payment(at)
      return true if paid?

      starts_from = [ user.premium_until, Date.current ].compact.max

      update!(status: :paid, paid_at: at, paid_through: starts_from + PERIOD)
    end
end
