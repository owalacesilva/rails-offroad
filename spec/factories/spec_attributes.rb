FactoryBot.define do
  factory :spec_attribute do
    sequence(:name) { |n| "atributo_#{n}" }
    data_type { "STRING" }
    sequence(:position) { |n| n }

    # Nomes reais do vocabulário, com rótulo em config/locales.
    trait :condition do
      name { "condition" }
      data_type { "STRING" }
      position { 1 }
    end

    trait :mileage do
      name { "mileage_km" }
      data_type { "INT" }
      position { 2 }
    end

    # Pedido por uma categoria. Estar ligado a ela é o que torna o atributo
    # obrigatório no formulário de anúncio.
    trait :for_category do
      transient do
        category { nil }
      end

      after(:create) do |spec_attribute, evaluator|
        create(:attribute_category, spec_attribute: spec_attribute,
                                    category: evaluator.category || create(:category))
      end
    end
  end
end
