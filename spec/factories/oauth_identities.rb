FactoryBot.define do
  factory :oauth_identity do
    user
    provider { "google" }
    # O uid é o identificador do provedor, opaco e único por provedor.
    sequence(:uid) { |n| "1078#{n.to_s.rjust(9, '0')}" }

    trait :facebook do
      provider { "facebook" }
    end
  end
end
