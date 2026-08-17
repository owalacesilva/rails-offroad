FactoryBot.define do
  factory :newsletter_subscription do
    sequence(:email) { |n| "assinante#{n}@exemplo.com.br" }
    source { "home" }
  end
end
