FactoryBot.define do
  factory :admin do
    name { "Equipe OffRoad" }
    sequence(:email) { |n| "moderador#{n}@offroadclassificados.com.br" }
    password { "trilha123" }
  end
end
