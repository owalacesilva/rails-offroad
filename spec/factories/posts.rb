FactoryBot.define do
  factory :post do
    admin
    sequence(:title) { |n| "Post de teste #{n}" }
    body { "<p>Corpo do post.</p>" }
    excerpt { nil }
    cover_url { nil }
    # Publicado por padrão: é o estado que o portal mostra.
    published_at { 1.day.ago }

    trait :draft do
      published_at { nil }
    end

    # Data marcada que ainda não chegou: some do público como o rascunho.
    trait :scheduled do
      published_at { 3.days.from_now }
    end

    trait :with_cover do
      cover_url { "https://exemplo.com.br/capa.jpg" }
    end
  end
end
