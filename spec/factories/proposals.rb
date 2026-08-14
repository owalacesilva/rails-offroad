FactoryBot.define do
  factory :proposal do
    listing

    name { "Walace Silva" }
    sequence(:email) { |n| "comprador#{n}@exemplo.com.br" }
    phone { "41999887766" }
    amount_cents { 35_000_000 }
    message { "Tenho interesse. Aceita troca?" }
  end
end
