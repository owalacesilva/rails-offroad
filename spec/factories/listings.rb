FactoryBot.define do
  factory :listing do
    category

    title { Faker::Vehicle.make_and_model }
    year { Faker::Number.between(from: 2000, to: Date.current.year) }
    price_cents { Faker::Number.between(from: 5_000, to: 500_000) * 100 }
    state { "PR" }
    city { "Curitiba" }
    published_at { Time.current }
    badge { nil }

    trait :featured do
      badge { :featured }
    end

    # Peça não tem ano: exercita o NULLS LAST da ordenação por ano.
    trait :without_year do
      year { nil }
    end
  end
end
