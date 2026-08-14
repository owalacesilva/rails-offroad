FactoryBot.define do
  factory :advertiser do
    name { "Garagem Trilha Livre" }
    sequence(:email) { |n| "anunciante#{n}@exemplo.com.br" }
    # wa.me exige só dígitos com código do país.
    phone { "5541988770011" }
    city { "Curitiba" }
    state { "PR" }
    member_since { Date.new(2020, 1, 15) }
  end
end
