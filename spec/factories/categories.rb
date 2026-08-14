FactoryBot.define do
  factory :category do
    sequence(:slug) { |n| "categoria-#{n}" }
    sequence(:position) { |n| n }

    # Slugs reais da taxonomia, com tradução em config/locales.
    trait :vehicles do
      slug { "veiculos-4x4" }
      position { 1 }
    end

    trait :bikes do
      slug { "motos-quadriciclos" }
      position { 2 }
    end

    trait :parts do
      slug { "pecas-acessorios" }
      position { 4 }
    end
  end
end
