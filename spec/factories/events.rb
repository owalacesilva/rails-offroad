FactoryBot.define do
  factory :event do
    sequence(:title) { |n| "Trilhão de Teste #{n}" }
    description { "Evento de teste." }
    # Futuro por padrão: a agenda da home só mostra o que ainda vai acontecer.
    starts_on { 10.days.from_now.to_date }
    ends_on { nil }
    city { "Curitiba" }
    state { "PR" }
    venue { "Parque de Exposições" }
    url { nil }

    # Vários dias: exercita o intervalo em event_dates e o single_day? falso.
    trait :multi_day do
      ends_on { starts_on + 2.days }
    end

    trait :past do
      starts_on { 10.days.ago.to_date }
      ends_on { nil }
    end

    # Começou antes de hoje e ainda não acabou: continua sendo "próximo".
    trait :ongoing do
      starts_on { 2.days.ago.to_date }
      ends_on { 2.days.from_now.to_date }
    end

    trait :with_url do
      url { "https://exemplo.com.br/evento" }
    end
  end
end
