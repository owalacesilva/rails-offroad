FactoryBot.define do
  factory :subscription do
    user
    # Sorteada, como em Subscription.open_for: viaja para fora do portal e volta
    # numa requisição pública, então não convém ser adivinhável em sequência.
    sequence(:gateway_reference) { |n| "PREMIUM-#{n.to_s.rjust(24, 'a')}" }
    amount_cents { 4_990 }
    status { "pending" }

    # Cobrança confirmada, valendo por um mês a partir de hoje: é o estado em que
    # o anunciante tem Premium.
    trait :paid do
      status { "paid" }
      paid_at { Time.current }
      paid_through { Date.current + Subscription::PERIOD }
    end

    # Pagou e o prazo venceu: pago, mas não é mais Premium.
    trait :expired do
      status { "paid" }
      paid_at { 2.months.ago }
      paid_through { Date.current - 1 }
    end
  end
end
