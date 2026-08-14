require "stringio"

# Idempotente: rodar `bin/rails db:seed` mais de uma vez não duplica registros
# nem reanexa fotos. Preços em reais inteiros; o seed converte para centavos.

CATEGORIES = [
  { slug: "veiculos-4x4", position: 1 },
  { slug: "motos-quadriciclos", position: 2 },
  { slug: "utvs", position: 3 },
  { slug: "pecas-acessorios", position: 4 }
].freeze

ADVERTISERS = [
  { name: "Garagem Trilha Livre", email: "contato@trilhalivre.com.br", phone: "5541988770011", city: "Curitiba", state: "PR", member_since: "2019-03-12" },
  { name: "Marcelo Andrade", email: "marcelo.andrade@exemplo.com.br", phone: "5511977660022", city: "São Paulo", state: "SP", member_since: "2021-07-04" },
  { name: "4x4 Sul Veículos", email: "vendas@4x4sul.com.br", phone: "5551966550033", city: "Porto Alegre", state: "RS", member_since: "2017-11-20" },
  { name: "Patrícia Nogueira", email: "patricia.nogueira@exemplo.com.br", phone: "5531955440044", city: "Belo Horizonte", state: "MG", member_since: "2022-01-18" },
  { name: "Off Road Center Goiás", email: "atendimento@orcgoias.com.br", phone: "5562944330055", city: "Goiânia", state: "GO", member_since: "2020-05-09" },
  { name: "Rodrigo Tavares", email: "rodrigo.tavares@exemplo.com.br", phone: "5565933220066", city: "Cuiabá", state: "MT", member_since: "2023-02-27" },
  { name: "Bahia Aventura Motos", email: "contato@bahiaaventura.com.br", phone: "5571922110077", city: "Salvador", state: "BA", member_since: "2018-09-15" },
  { name: "Camila Duarte", email: "camila.duarte@exemplo.com.br", phone: "5548911000088", city: "Joinville", state: "SC", member_since: "2024-04-02" }
].freeze

# Especificações comuns à categoria; cada anúncio sobrescreve o que for próprio.
CATEGORY_SPECS = {
  "veiculos-4x4" => { "condition" => "Usado", "traction" => "4x4 com reduzida", "doors" => 4 },
  "motos-quadriciclos" => { "condition" => "Usado", "fuel" => "Gasolina" },
  "utvs" => { "condition" => "Usado", "traction" => "4x4 selecionável", "fuel" => "Gasolina" },
  "pecas-acessorios" => { "condition" => "Novo", "warranty" => "12 meses" }
}.freeze

# Dois textos por categoria, alternados pelo índice — seed não é copywriting.
DESCRIPTIONS = {
  "veiculos-4x4" => [
    "%{title} em ótimo estado de conservação, revisões sempre feitas em concessionária e documentação em dia.\n\nPneus com folga de vida útil, sem retoque de pintura e sem passagem por leilão. Aceito avaliação técnica antes da compra.",
    "%{title} pronto para pegar estrada de terra no fim de semana. Suspensão e freios revisados recentemente, sem detalhes de lataria.\n\nSegundo dono, sempre guardado em garagem coberta. Aceito troca por veículo de menor valor."
  ],
  "motos-quadriciclos" => [
    "%{title} com manutenção em dia e uso recreativo apenas em trilha. Nunca sofreu queda séria, sem empenos.\n\nAcompanha kit de relação novo e manual. Chassi e documentação sem qualquer pendência.",
    "%{title} revisada e regulada, pronta para rodar. Óleo, filtros e pastilhas trocados na última revisão.\n\nMoto de garagem, usada em trilhas leves nos fins de semana. Aceito proposta à vista."
  ],
  "utvs" => [
    "%{title} com poucas horas de uso, sempre em areia e terra seca. Revisão completa feita na autorizada.\n\nAcompanha capota, cintos de quatro pontos e gaiola original. Documentação em ordem para transferência.",
    "%{title} em excelente estado, motor e transmissão sem qualquer intervenção. Amortecedores recém-revisados.\n\nUsado apenas em eventos e passeios organizados. Aceito avaliação mecânica de sua confiança."
  ],
  "pecas-acessorios" => [
    "%{title} novo, na caixa, com nota fiscal e garantia do fabricante.\n\nEnvio para todo o Brasil por transportadora ou retirada no local. Consulte compatibilidade antes de fechar.",
    "%{title} lacrado e sem uso, sobra de um projeto que mudou de direção.\n\nAcompanha todos os itens de instalação originais. Envio no mesmo dia da confirmação do pagamento."
  ]
}.freeze

LISTINGS = [
  # Veículos 4x4
  { title: "Jeep Wrangler Rubicon 3.6 V6", year: 2019, price: 389_900, city: "Curitiba", state: "PR", category: "veiculos-4x4", badge: :prepared,
    specs: { "engine" => "3.6 V6 Pentastar", "transmission" => "Automático 8 marchas", "fuel" => "Gasolina", "mileage_km" => 48_000, "color" => "Verde", "doors" => 2 } },
  { title: "Toyota Hilux SW4 SRX 2.8", year: 2021, price: 349_900, city: "São Paulo", state: "SP", category: "veiculos-4x4", badge: :featured,
    specs: { "engine" => "2.8 turbodiesel", "transmission" => "Automático 6 marchas", "fuel" => "Diesel", "mileage_km" => 62_400, "color" => "Prata" } },
  { title: "Ford Ranger Raptor 2.0 Bi-Turbo", year: 2022, price: 359_000, city: "Campinas", state: "SP", category: "veiculos-4x4", badge: nil,
    specs: { "engine" => "2.0 Bi-Turbo", "transmission" => "Automático 10 marchas", "fuel" => "Diesel", "mileage_km" => 38_900, "color" => "Azul" } },
  { title: "Land Rover Defender 110 D300", year: 2020, price: 520_000, city: "Rio de Janeiro", state: "RJ", category: "veiculos-4x4", badge: :featured,
    specs: { "engine" => "3.0 D300 mild hybrid", "transmission" => "Automático 8 marchas", "fuel" => "Diesel", "mileage_km" => 41_200, "color" => "Cinza" } },
  { title: "Troller T4 3.2 TGV", year: 2018, price: 219_900, city: "Belo Horizonte", state: "MG", category: "veiculos-4x4", badge: :prepared,
    specs: { "engine" => "3.2 turbodiesel", "transmission" => "Manual 6 marchas", "fuel" => "Diesel", "mileage_km" => 78_500, "color" => "Preto", "doors" => 2 } },
  { title: "Jeep Renegade Trailhawk 2.0", year: 2020, price: 149_900, city: "Curitiba", state: "PR", category: "veiculos-4x4", badge: nil,
    specs: { "engine" => "2.0 turbodiesel", "transmission" => "Automático 9 marchas", "fuel" => "Diesel", "mileage_km" => 71_300, "color" => "Branco" } },
  { title: "Mitsubishi L200 Triton Sport HPE-S", year: 2019, price: 189_900, city: "Goiânia", state: "GO", category: "veiculos-4x4", badge: nil,
    specs: { "engine" => "2.4 turbodiesel", "transmission" => "Automático 8 marchas", "fuel" => "Diesel", "mileage_km" => 89_700, "color" => "Prata" } },
  { title: "Chevrolet S10 High Country 2.8", year: 2021, price: 244_900, city: "Porto Alegre", state: "RS", category: "veiculos-4x4", badge: nil,
    specs: { "engine" => "2.8 turbodiesel", "transmission" => "Automático 6 marchas", "fuel" => "Diesel", "mileage_km" => 55_100, "color" => "Vermelho" } },
  { title: "Suzuki Jimny Sierra 1.5 4x4", year: 2022, price: 179_900, city: "Joinville", state: "SC", category: "veiculos-4x4", badge: :new_arrival,
    specs: { "engine" => "1.5 aspirado", "transmission" => "Manual 5 marchas", "fuel" => "Gasolina", "mileage_km" => 22_800, "color" => "Amarelo", "doors" => 2 } },
  { title: "Toyota Bandeirante OJ-55 Longa", year: 1994, price: 145_000, city: "Cuiabá", state: "MT", category: "veiculos-4x4", badge: :prepared,
    specs: { "engine" => "4.0 diesel Mercedes", "transmission" => "Manual 4 marchas", "fuel" => "Diesel", "mileage_km" => 210_000, "color" => "Bege", "doors" => 2 } },
  { title: "Nissan Frontier Attack 2.3", year: 2020, price: 209_900, city: "Salvador", state: "BA", category: "veiculos-4x4", badge: nil,
    specs: { "engine" => "2.3 Bi-Turbo", "transmission" => "Automático 7 marchas", "fuel" => "Diesel", "mileage_km" => 66_400, "color" => "Branco" } },
  { title: "Jeep Gladiator Overland 3.6", year: 2023, price: 449_000, city: "Brasília", state: "DF", category: "veiculos-4x4", badge: :new_arrival,
    specs: { "engine" => "3.6 V6 Pentastar", "transmission" => "Automático 8 marchas", "fuel" => "Gasolina", "mileage_km" => 14_500, "color" => "Cinza" } },

  # Motos e quadriciclos
  { title: "Honda XR 300 Tornado", year: 2021, price: 24_500, city: "Belo Horizonte", state: "MG", category: "motos-quadriciclos", badge: nil,
    specs: { "engine" => "300 cc monocilíndrico", "power" => "26 cv", "mileage_km" => 18_900, "color" => "Vermelho" } },
  { title: "Yamaha Lander 250 ABS", year: 2022, price: 21_900, city: "São Paulo", state: "SP", category: "motos-quadriciclos", badge: nil,
    specs: { "engine" => "250 cc Blue Core", "power" => "21 cv", "mileage_km" => 12_400, "color" => "Azul" } },
  { title: "Honda CRF 250F", year: 2023, price: 32_900, city: "Campinas", state: "SP", category: "motos-quadriciclos", badge: :new_arrival,
    specs: { "engine" => "250 cc refrigerado a ar", "power" => "19 cv", "mileage_km" => 3_100, "color" => "Vermelho" } },
  { title: "KTM 350 EXC-F Six Days", year: 2022, price: 78_900, city: "Curitiba", state: "PR", category: "motos-quadriciclos", badge: :featured,
    specs: { "engine" => "350 cc SOHC", "power" => "46 cv", "mileage_km" => 6_800, "color" => "Laranja" } },
  { title: "Yamaha WR 450F", year: 2021, price: 62_000, city: "Porto Alegre", state: "RS", category: "motos-quadriciclos", badge: :prepared,
    specs: { "engine" => "450 cc refrigerado a líquido", "power" => "58 cv", "mileage_km" => 9_500, "color" => "Azul" } },
  { title: "Kawasaki KLX 230 S", year: 2023, price: 26_900, city: "Joinville", state: "SC", category: "motos-quadriciclos", badge: nil,
    specs: { "engine" => "233 cc monocilíndrico", "power" => "18 cv", "mileage_km" => 4_200, "color" => "Verde" } },
  { title: "Honda Fourtrax 420 4x4", year: 2020, price: 54_900, city: "Goiânia", state: "GO", category: "motos-quadriciclos", badge: nil,
    specs: { "engine" => "420 cc", "power" => "27 cv", "traction" => "4x4", "mileage_km" => 7_600, "color" => "Vermelho" } },
  { title: "Yamaha Grizzly 700 EPS", year: 2019, price: 68_900, city: "Cuiabá", state: "MT", category: "motos-quadriciclos", badge: nil,
    specs: { "engine" => "686 cc", "power" => "46 cv", "traction" => "4x4", "mileage_km" => 11_300, "color" => "Verde" } },
  { title: "Sherco SE 300 Factory", year: 2023, price: 84_900, city: "Rio de Janeiro", state: "RJ", category: "motos-quadriciclos", badge: :new_arrival,
    specs: { "engine" => "300 cc dois tempos", "power" => "52 cv", "mileage_km" => 2_400, "color" => "Azul" } },
  { title: "Honda XRE 300 Rally", year: 2020, price: 23_900, city: "Salvador", state: "BA", category: "motos-quadriciclos", badge: nil,
    specs: { "engine" => "300 cc monocilíndrico", "power" => "26 cv", "mileage_km" => 27_800, "color" => "Preto" } },

  # UTVs
  { title: "Can-Am Maverick X3 Turbo RR", year: 2023, price: 415_000, city: "Campinas", state: "SP", category: "utvs", badge: :featured,
    specs: { "engine" => "900 cc turbo tricilíndrico", "power" => "195 cv", "transmission" => "CVT", "mileage_km" => 2_900, "color" => "Amarelo" } },
  { title: "Polaris RZR Pro XP Ultimate", year: 2022, price: 389_000, city: "São Paulo", state: "SP", category: "utvs", badge: nil,
    specs: { "engine" => "925 cc turbo", "power" => "181 cv", "transmission" => "CVT", "mileage_km" => 4_100, "color" => "Cinza" } },
  { title: "Can-Am Outlander 850 XMR", year: 2021, price: 118_900, city: "Brasília", state: "DF", category: "utvs", badge: nil,
    specs: { "engine" => "854 cc V-twin", "power" => "78 cv", "transmission" => "CVT", "mileage_km" => 6_300, "color" => "Camuflado" } },
  { title: "Honda Talon 1000R", year: 2022, price: 329_000, city: "Curitiba", state: "PR", category: "utvs", badge: nil,
    specs: { "engine" => "999 cc bicilíndrico", "power" => "104 cv", "transmission" => "DCT 6 marchas", "mileage_km" => 3_800, "color" => "Vermelho" } },
  { title: "CFMOTO ZForce 950 Sport", year: 2023, price: 189_900, city: "Goiânia", state: "GO", category: "utvs", badge: :new_arrival,
    specs: { "engine" => "963 cc bicilíndrico", "power" => "79 cv", "transmission" => "CVT", "mileage_km" => 1_700, "color" => "Laranja" } },
  { title: "Polaris General 1000 Deluxe", year: 2020, price: 245_000, city: "Cuiabá", state: "MT", category: "utvs", badge: :prepared,
    specs: { "engine" => "999 cc ProStar", "power" => "100 cv", "transmission" => "CVT", "mileage_km" => 8_900, "color" => "Preto" } },

  # Peças e acessórios (sem ano: exercita o NULLS LAST da ordenação)
  { title: "Kit Suspensão Old Man Emu +2\"", year: nil, price: 8_790, city: "Porto Alegre", state: "RS", category: "pecas-acessorios", badge: :new_arrival,
    specs: { "brand" => "ARB Old Man Emu", "material" => "Aço com molas helicoidais" } },
  { title: "Guincho Elétrico 12.000 lbs", year: 2024, price: 5_490, city: "São Paulo", state: "SP", category: "pecas-acessorios", badge: nil,
    specs: { "brand" => "Superwinch", "material" => "Cabo sintético" } },
  { title: "Snorkel Safari para Hilux", year: nil, price: 2_890, city: "Curitiba", state: "PR", category: "pecas-acessorios", badge: nil,
    specs: { "brand" => "Safari 4x4", "material" => "Polietileno rotomoldado" } },
  { title: "Jogo de Pneus BFGoodrich KM3 33\"", year: 2024, price: 9_800, city: "Belo Horizonte", state: "MG", category: "pecas-acessorios", badge: :featured,
    specs: { "brand" => "BFGoodrich", "material" => "Borracha mud-terrain" } },
  { title: "Bagageiro de Teto Expedition", year: nil, price: 4_300, city: "Joinville", state: "SC", category: "pecas-acessorios", badge: nil,
    specs: { "brand" => "Front Runner", "material" => "Alumínio anodizado" } },
  { title: "Para-choque Off-road ATM", year: nil, price: 3_950, city: "Goiânia", state: "GO", category: "pecas-acessorios", badge: nil,
    specs: { "brand" => "ATM Bumpers", "material" => "Aço carbono 3 mm" } },
  { title: "Bloqueio de Diferencial ARB Air Locker", year: 2023, price: 12_900, city: "Rio de Janeiro", state: "RJ", category: "pecas-acessorios", badge: :prepared,
    specs: { "brand" => "ARB", "material" => "Aço forjado" } },
  { title: "Barra de LED Auxiliar 52\"", year: nil, price: 1_290, city: "Salvador", state: "BA", category: "pecas-acessorios", badge: nil,
    specs: { "brand" => "Rigid Industries", "material" => "Alumínio com lente PC" } }
].freeze

# Tons de terra, ferrugem e mata fechada para os placeholders de foto.
PALETTES = [
  [ [ 87, 83, 78 ], [ 12, 10, 9 ] ],
  [ [ 146, 64, 14 ], [ 28, 25, 23 ] ],
  [ [ 63, 98, 18 ], [ 12, 10, 9 ] ],
  [ [ 120, 53, 15 ], [ 23, 23, 23 ] ],
  [ [ 68, 64, 60 ], [ 28, 25, 23 ] ],
  [ [ 154, 52, 18 ], [ 12, 10, 9 ] ]
].freeze

PHOTOS_PER_LISTING = 3

# Gerar o PNG é o passo caro; o upload repete os mesmos bytes.
def photo_bytes(palette_index)
  @photo_cache ||= {}
  @photo_cache[palette_index] ||= begin
    top, bottom = PALETTES[palette_index % PALETTES.size]
    PlaceholderImage.new(width: 800, height: 600, top: top, bottom: bottom).to_png
  end
end

advertisers = ADVERTISERS.map do |attributes|
  advertiser = Advertiser.find_or_initialize_by(email: attributes[:email])
  advertiser.update!(attributes)
  advertiser
end

categories = CATEGORIES.each_with_object({}) do |attributes, memo|
  category = Category.find_or_initialize_by(slug: attributes[:slug])
  category.update!(position: attributes[:position])
  memo[attributes[:slug]] = category
end

LISTINGS.each_with_index do |attributes, index|
  slug = attributes[:category]
  variants = DESCRIPTIONS.fetch(slug)

  listing = Listing.find_or_initialize_by(title: attributes[:title])
  listing.update!(
    year: attributes[:year],
    price_cents: attributes[:price] * 100,
    city: attributes[:city],
    state: attributes[:state],
    badge: attributes[:badge],
    category: categories.fetch(slug),
    advertiser: advertisers[index % advertisers.size],
    description: format(variants[index % variants.size], title: attributes[:title]),
    specifications: CATEGORY_SPECS.fetch(slug).merge(attributes[:specs]),
    # Escalona a publicação para a ordenação "mais recentes" fazer sentido.
    published_at: index.days.ago
  )

  next if listing.photos.attached?

  listing.photos.attach(
    Array.new(PHOTOS_PER_LISTING) do |photo_index|
      {
        io: StringIO.new(photo_bytes(index + photo_index)),
        filename: "#{listing.id}-#{photo_index + 1}.png",
        content_type: "image/png"
      }
    end
  )
end

# O backfill da migration criou um anunciante placeholder para a coluna virar
# NOT NULL. Agora que todo anúncio tem dono de verdade, ele sai.
Advertiser.where(email: "migrar@offroadclassificados.com.br").where.missing(:listings).destroy_all

# Conta só as fotos anexadas aos anúncios: o Active Storage também cria
# attachment para cada variante materializada, e isso não é dado de seed.
photos = ActiveStorage::Attachment.where(record_type: "Listing", name: "photos").count

puts "Seed: #{Category.count} categorias, #{Advertiser.count} anunciantes, " \
     "#{Listing.count} anúncios, #{photos} fotos."
