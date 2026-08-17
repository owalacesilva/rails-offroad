FactoryBot.define do
  factory :city do
    # Código do IBGE tem 7 dígitos e nunca começa em zero — a sequência começa
    # no bloco de SP para não esbarrar na check constraint.
    sequence(:ibge_code) { |n| (3_500_000 + n).to_s }
    sequence(:name) { |n| "Município de Teste #{n}" }
    state { "PR" }

    trait :sao_paulo do
      ibge_code { "3550308" }
      name { "São Paulo" }
      state { "SP" }
    end

    trait :curitiba do
      ibge_code { "4106902" }
      name { "Curitiba" }
      state { "PR" }
    end
  end
end
