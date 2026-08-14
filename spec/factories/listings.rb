FactoryBot.define do
  factory :listing do
    category
    advertiser

    title { Faker::Vehicle.make_and_model }
    year { Faker::Number.between(from: 2000, to: Date.current.year) }
    price_cents { Faker::Number.between(from: 5_000, to: 500_000) * 100 }
    state { "PR" }
    city { "Curitiba" }
    published_at { Time.current }
    badge { nil }
    description { "Anúncio de teste." }
    specifications { { "condition" => "Usado" } }

    trait :featured do
      badge { :featured }
    end

    # Peça não tem ano: exercita o NULLS LAST da ordenação por ano.
    trait :without_year do
      year { nil }
    end

    trait :with_photos do
      transient do
        photo_count { 2 }
      end

      after(:build) do |listing, evaluator|
        png = PlaceholderImage.new(width: 40, height: 30, top: [ 90, 80, 70 ], bottom: [ 10, 10, 10 ]).to_png

        evaluator.photo_count.times do |index|
          listing.photos.attach(
            io: StringIO.new(png), filename: "foto-#{index + 1}.png", content_type: "image/png"
          )
        end
      end
    end
  end
end
