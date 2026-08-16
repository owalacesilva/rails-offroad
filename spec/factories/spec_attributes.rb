FactoryBot.define do
  factory :spec_attribute do
    sequence(:name) { |n| "atributo_#{n}" }
    data_type { "STRING" }
    is_required { false }
    sequence(:position) { |n| n }

    # Nomes reais do vocabulário, com rótulo em config/locales.
    trait :condition do
      name { "condition" }
      data_type { "STRING" }
      is_required { true }
      position { 1 }
    end

    trait :mileage do
      name { "mileage_km" }
      data_type { "INT" }
      position { 2 }
    end
  end
end
