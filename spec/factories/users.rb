FactoryBot.define do
  factory :user do
    name { "Garagem Trilha Livre" }
    sequence(:email) { |n| "anunciante#{n}@exemplo.com.br" }
    # wa.me exige só dígitos com código do país.
    phone { "5541988770011" }
    city { "Curitiba" }
    state { "PR" }
    member_since { Date.new(2020, 1, 15) }
    password { "trilha123" }
    # Confirmado por padrão: é o estado em que o anunciante passa a vida toda, e
    # deixar o padrão em "pendente" faria todo spec de área logada confirmar
    # antes de começar.
    confirmed_at { Time.current }

    trait :unconfirmed do
      confirmed_at { nil }
    end

    trait :with_google do
      after(:create) { |user| create(:oauth_identity, user: user) }
    end
  end
end
