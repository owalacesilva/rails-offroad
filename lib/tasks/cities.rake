namespace :cities do
  desc "Popula a tabela cities com os municípios do IBGE (db/cities.csv). Idempotente."
  task import: :environment do
    # Existe separado do db:seed porque este é o único dado de referência do
    # projeto: o resto do seed é amostra de desenvolvimento e não roda em
    # produção, enquanto os municípios precisam existir em qualquer ambiente.
    puts "Municípios carregados: #{BrazilianCities.import}."
  end
end
