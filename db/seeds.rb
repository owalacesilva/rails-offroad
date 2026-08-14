# Idempotente: rodar `bin/rails db:seed` mais de uma vez não duplica registros.
# Preços em reais inteiros; o seed converte para centavos.

CATEGORIES = [
  { slug: "veiculos-4x4", position: 1 },
  { slug: "motos-quadriciclos", position: 2 },
  { slug: "utvs", position: 3 },
  { slug: "pecas-acessorios", position: 4 }
].freeze

LISTINGS = [
  # Veículos 4x4
  { title: "Jeep Wrangler Rubicon 3.6 V6", year: 2019, price: 389_900, city: "Curitiba", state: "PR", category: "veiculos-4x4", badge: :prepared },
  { title: "Toyota Hilux SW4 SRX 2.8", year: 2021, price: 349_900, city: "São Paulo", state: "SP", category: "veiculos-4x4", badge: :featured },
  { title: "Ford Ranger Raptor 2.0 Bi-Turbo", year: 2022, price: 359_000, city: "Campinas", state: "SP", category: "veiculos-4x4", badge: nil },
  { title: "Land Rover Defender 110 D300", year: 2020, price: 520_000, city: "Rio de Janeiro", state: "RJ", category: "veiculos-4x4", badge: :featured },
  { title: "Troller T4 3.2 TGV", year: 2018, price: 219_900, city: "Belo Horizonte", state: "MG", category: "veiculos-4x4", badge: :prepared },
  { title: "Jeep Renegade Trailhawk 2.0", year: 2020, price: 149_900, city: "Curitiba", state: "PR", category: "veiculos-4x4", badge: nil },
  { title: "Mitsubishi L200 Triton Sport HPE-S", year: 2019, price: 189_900, city: "Goiânia", state: "GO", category: "veiculos-4x4", badge: nil },
  { title: "Chevrolet S10 High Country 2.8", year: 2021, price: 244_900, city: "Porto Alegre", state: "RS", category: "veiculos-4x4", badge: nil },
  { title: "Suzuki Jimny Sierra 1.5 4x4", year: 2022, price: 179_900, city: "Joinville", state: "SC", category: "veiculos-4x4", badge: :new_arrival },
  { title: "Toyota Bandeirante OJ-55 Longa", year: 1994, price: 145_000, city: "Cuiabá", state: "MT", category: "veiculos-4x4", badge: :prepared },
  { title: "Nissan Frontier Attack 2.3", year: 2020, price: 209_900, city: "Salvador", state: "BA", category: "veiculos-4x4", badge: nil },
  { title: "Jeep Gladiator Overland 3.6", year: 2023, price: 449_000, city: "Brasília", state: "DF", category: "veiculos-4x4", badge: :new_arrival },

  # Motos e quadriciclos
  { title: "Honda XR 300 Tornado", year: 2021, price: 24_500, city: "Belo Horizonte", state: "MG", category: "motos-quadriciclos", badge: nil },
  { title: "Yamaha Lander 250 ABS", year: 2022, price: 21_900, city: "São Paulo", state: "SP", category: "motos-quadriciclos", badge: nil },
  { title: "Honda CRF 250F", year: 2023, price: 32_900, city: "Campinas", state: "SP", category: "motos-quadriciclos", badge: :new_arrival },
  { title: "KTM 350 EXC-F Six Days", year: 2022, price: 78_900, city: "Curitiba", state: "PR", category: "motos-quadriciclos", badge: :featured },
  { title: "Yamaha WR 450F", year: 2021, price: 62_000, city: "Porto Alegre", state: "RS", category: "motos-quadriciclos", badge: :prepared },
  { title: "Kawasaki KLX 230 S", year: 2023, price: 26_900, city: "Joinville", state: "SC", category: "motos-quadriciclos", badge: nil },
  { title: "Honda Fourtrax 420 4x4", year: 2020, price: 54_900, city: "Goiânia", state: "GO", category: "motos-quadriciclos", badge: nil },
  { title: "Yamaha Grizzly 700 EPS", year: 2019, price: 68_900, city: "Cuiabá", state: "MT", category: "motos-quadriciclos", badge: nil },
  { title: "Sherco SE 300 Factory", year: 2023, price: 84_900, city: "Rio de Janeiro", state: "RJ", category: "motos-quadriciclos", badge: :new_arrival },
  { title: "Honda XRE 300 Rally", year: 2020, price: 23_900, city: "Salvador", state: "BA", category: "motos-quadriciclos", badge: nil },

  # UTVs
  { title: "Can-Am Maverick X3 Turbo RR", year: 2023, price: 415_000, city: "Campinas", state: "SP", category: "utvs", badge: :featured },
  { title: "Polaris RZR Pro XP Ultimate", year: 2022, price: 389_000, city: "São Paulo", state: "SP", category: "utvs", badge: nil },
  { title: "Can-Am Outlander 850 XMR", year: 2021, price: 118_900, city: "Brasília", state: "DF", category: "utvs", badge: nil },
  { title: "Honda Talon 1000R", year: 2022, price: 329_000, city: "Curitiba", state: "PR", category: "utvs", badge: nil },
  { title: "CFMOTO ZForce 950 Sport", year: 2023, price: 189_900, city: "Goiânia", state: "GO", category: "utvs", badge: :new_arrival },
  { title: "Polaris General 1000 Deluxe", year: 2020, price: 245_000, city: "Cuiabá", state: "MT", category: "utvs", badge: :prepared },

  # Peças e acessórios (sem ano: exercita o NULLS LAST da ordenação)
  { title: "Kit Suspensão Old Man Emu +2\"", year: nil, price: 8_790, city: "Porto Alegre", state: "RS", category: "pecas-acessorios", badge: :new_arrival },
  { title: "Guincho Elétrico 12.000 lbs", year: 2024, price: 5_490, city: "São Paulo", state: "SP", category: "pecas-acessorios", badge: nil },
  { title: "Snorkel Safari para Hilux", year: nil, price: 2_890, city: "Curitiba", state: "PR", category: "pecas-acessorios", badge: nil },
  { title: "Jogo de Pneus BFGoodrich KM3 33\"", year: 2024, price: 9_800, city: "Belo Horizonte", state: "MG", category: "pecas-acessorios", badge: :featured },
  { title: "Bagageiro de Teto Expedition", year: nil, price: 4_300, city: "Joinville", state: "SC", category: "pecas-acessorios", badge: nil },
  { title: "Para-choque Off-road ATM", year: nil, price: 3_950, city: "Goiânia", state: "GO", category: "pecas-acessorios", badge: nil },
  { title: "Bloqueio de Diferencial ARB Air Locker", year: 2023, price: 12_900, city: "Rio de Janeiro", state: "RJ", category: "pecas-acessorios", badge: :prepared },
  { title: "Barra de LED Auxiliar 52\"", year: nil, price: 1_290, city: "Salvador", state: "BA", category: "pecas-acessorios", badge: nil }
].freeze

categories = CATEGORIES.each_with_object({}) do |attributes, memo|
  category = Category.find_or_initialize_by(slug: attributes[:slug])
  category.update!(position: attributes[:position])
  memo[attributes[:slug]] = category
end

LISTINGS.each_with_index do |attributes, index|
  listing = Listing.find_or_initialize_by(title: attributes[:title])
  listing.update!(
    year: attributes[:year],
    price_cents: attributes[:price] * 100,
    city: attributes[:city],
    state: attributes[:state],
    badge: attributes[:badge],
    category: categories.fetch(attributes[:category]),
    # Escalona a publicação para a ordenação "mais recentes" fazer sentido.
    published_at: index.days.ago
  )
end

puts "Seed: #{Category.count} categorias, #{Listing.count} anúncios."
