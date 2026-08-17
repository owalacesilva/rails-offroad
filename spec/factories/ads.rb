FactoryBot.define do
  # Uma URL por foto, única em toda a suíte: a galeria da home junta fotos de
  # vários anúncios, e com URLs repetidas não daria para dizer de quem é qual.
  sequence(:ad_photo_url) { |n| "/seed-images/anuncio-#{n}.png" }

  factory :ad do
    category
    user

    title { Faker::Vehicle.make_and_model }
    year { Faker::Number.between(from: 2000, to: Date.current.year) }
    # DECIMAL em reais, com centavos.
    price { Faker::Number.between(from: 5_000, to: 500_000) + 0.99 }
    state { "PR" }
    city { "Curitiba" }
    published_at { Time.current }
    # Aprovado por padrão: é o único status que aparece no portal, então é o
    # que a maioria dos specs precisa.
    status { :approved }
    badge { nil }
    description { "Anúncio de teste." }

    transient do
      image_count { Ad::IMAGE_COUNT.min }
    end

    # Anúncio aprovado só é válido com 3 a 10 fotos, então a factory já nasce
    # com o mínimo. Fotos entram no build para a validação enxergá-las.
    after(:build) do |ad, evaluator|
      next if ad.ad_images.any?

      evaluator.image_count.times do |index|
        ad.ad_images.build(file_url: generate(:ad_photo_url), sort_order: index)
      end
    end

    trait :featured do
      badge { :featured }
    end

    # Peça não tem ano: exercita a posição dos nulos na ordenação por ano.
    trait :without_year do
      year { nil }
    end

    trait :with_photos do
      transient do
        photo_count { 3 }
      end

      image_count { photo_count }
    end

    # Status fora de aprovado não exige fotos e não aparece no portal.
    trait :pending do
      status { :pending }
      published_at { nil }
      image_count { 0 }
    end

    trait :draft do
      status { :draft }
      published_at { nil }
      image_count { 0 }
    end

    trait :rejected do
      status { :rejected }
      image_count { 0 }
    end

    # Especificações no formato EAV.
    trait :with_specs do
      transient do
        specs { { "condition" => "Usado" } }
      end

      after(:create) do |ad, evaluator|
        evaluator.specs.each_with_index do |(name, value), index|
          attribute = SpecAttribute.find_or_create_by!(name: name) do |record|
            record.data_type = value.is_a?(Integer) ? "INT" : "STRING"
            record.position = index + 1
          end

          TechnicalSpecValue.create!(ad: ad, spec_attribute: attribute, value: value.to_s)
        end
      end
    end
  end
end
