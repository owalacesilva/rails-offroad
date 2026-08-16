FactoryBot.define do
  factory :proposal do
    ad

    name { "Walace Silva" }
    sequence(:email) { |n| "comprador#{n}@exemplo.com.br" }
    phone { "41999887766" }
    # DECIMAL em reais.
    offered_value { 350_000.00 }
    message { "Tenho interesse. Aceita troca?" }
  end
end
