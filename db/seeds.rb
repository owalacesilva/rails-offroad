require "stringio"

# Idempotente: rodar `bin/rails db:seed` mais de uma vez não duplica registros
# nem reescreve fotos. Preços em reais (DECIMAL), sem conversão para centavos.

CATEGORIES = [
  { slug: "veiculos-4x4", position: 1 },
  { slug: "motos-quadriciclos", position: 2 },
  { slug: "utvs", position: 3 },
  { slug: "pecas-acessorios", position: 4 }
].freeze

# Senha única para todos os anunciantes semeados, só para conseguir entrar em
# desenvolvimento. Nada disto roda em produção.
SEED_PASSWORD = "trilha123".freeze

USERS = [
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

ADS = [
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

  # Peças e acessórios (sem ano: exercita a posição dos nulos na ordenação)
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

PHOTOS_PER_AD = 3

# Moderadores. Identidade separada da de anunciante.
ADMINS = [
  { name: "Equipe OffRoad", email: "moderacao@offroadclassificados.com.br" }
].freeze

# Lado "Attribute" do EAV. A ordem de exibição é a coluna position — antes era
# uma constante no modelo, porque jsonb não preservava a ordem das chaves.
SPEC_ATTRIBUTES = [
  { name: "condition",    data_type: "STRING", position: 1,  is_required: true },
  { name: "mileage_km",   data_type: "INT",    position: 2,  is_required: false },
  { name: "engine",       data_type: "STRING", position: 3,  is_required: false },
  { name: "power",        data_type: "STRING", position: 4,  is_required: false },
  { name: "transmission", data_type: "STRING", position: 5,  is_required: false },
  { name: "traction",     data_type: "STRING", position: 6,  is_required: false },
  { name: "fuel",         data_type: "STRING", position: 7,  is_required: false },
  { name: "doors",        data_type: "INT",    position: 8,  is_required: false },
  { name: "color",        data_type: "STRING", position: 9,  is_required: false },
  { name: "brand",        data_type: "STRING", position: 10, is_required: false },
  { name: "material",     data_type: "STRING", position: 11, is_required: false },
  { name: "warranty",     data_type: "STRING", position: 12, is_required: false }
].freeze

# Propostas recebidas. `ad` é o título do anúncio; `user` é o e-mail de um
# anunciante já semeado, para o caso de quem envia estar logado — aí nome e
# e-mail saem do próprio cadastro. Sem `user` é proposta anônima, que o portal
# aceita de propósito, e o nome e o e-mail vêm da linha.
#
# `days_after` conta a partir da publicação do anúncio: proposta não chega antes
# do anúncio existir. Valor sempre abaixo do preço pedido — é uma oferta.
#
# O telefone fica como o comprador digitaria: diferente de User, Proposal não
# normaliza, porque este número só é exibido ao anunciante, não vira link wa.me.
PROPOSALS = [
  # Um anúncio disputado, para o painel do anunciante não ter só uma linha.
  { ad: "Jeep Gladiator Overland 3.6", name: "Eduardo Bastos", email: "eduardo.bastos@exemplo.com.br",
    phone: "(41) 99876-5544", offered_value: 425_000, days_after: 2,
    message: "Tenho interesse real e pago à vista. Consigo ir buscar em Belo Horizonte ainda este mês.\n\nA garantia de fábrica ainda está válida?" },
  { ad: "Jeep Gladiator Overland 3.6", user: "rodrigo.tavares@exemplo.com.br",
    phone: "(65) 99332-2066", offered_value: 432_000, days_after: 5,
    message: "Trabalho com off-road e conheço bem o modelo. Aceita troca parcial em um Troller 2019?" },
  { ad: "Jeep Gladiator Overland 3.6", name: "Letícia Moraes", email: "leticia.moraes@exemplo.com.br",
    phone: nil, offered_value: 410_000, days_after: 9, message: nil },

  { ad: "Toyota Bandeirante OJ-55 Longa", name: "Fernando Queiroz", email: "fernando.queiroz@exemplo.com.br",
    phone: "(11) 98123-4477", offered_value: 138_000, days_after: 4,
    message: "Procuro uma Bandeirante original há meses. Tem o manual e a chave reserva?" },

  { ad: "Nissan Frontier Attack 2.3", user: "camila.duarte@exemplo.com.br",
    phone: "(48) 99100-0088", offered_value: 198_000, days_after: 3,
    message: "Posso fechar esta semana se aceitar o valor. Levaria a um mecânico de confiança em Porto Alegre antes." },
  { ad: "Nissan Frontier Attack 2.3", name: "Juliana Prado", email: "juliana.prado@exemplo.com.br",
    phone: "(51) 99654-1122", offered_value: 205_000, days_after: 7, message: nil },

  { ad: "Troller T4 3.2 TGV", name: "Thiago Menezes", email: "thiago.menezes@exemplo.com.br",
    phone: "(62) 98877-3311", offered_value: 208_000, days_after: 2,
    message: "É o meu carro dos sonhos. Consigo dar entrada agora e o restante em até dez dias." },

  { ad: "Jeep Renegade Trailhawk 2.0", user: "marcelo.andrade@exemplo.com.br",
    phone: "(11) 97766-0022", offered_value: 141_000, days_after: 3,
    message: "Tem laudo cautelar recente? Se tiver, fecho pelo valor da proposta sem pechinchar." },

  { ad: "Mitsubishi L200 Triton Sport HPE-S", name: "Sandra Vasconcelos", email: "sandra.vasconcelos@exemplo.com.br",
    phone: nil, offered_value: 179_000, days_after: 4,
    message: "Uso para trabalho no campo, então rodagem alta não é problema. Aguardo retorno." },

  { ad: "Chevrolet S10 High Country 2.8", name: "Otávio Lins", email: "otavio.lins@exemplo.com.br",
    phone: "(48) 99201-7788", offered_value: 232_000, days_after: 5,
    message: "Vi o anúncio hoje e gostei das fotos. Aceita financiamento com entrada de 40%?" },

  { ad: "Suzuki Jimny Sierra 1.5 4x4", user: "patricia.nogueira@exemplo.com.br",
    phone: "(31) 99544-0044", offered_value: 170_000, days_after: 6,
    message: "Estou montando um segundo carro só para trilha leve. O Jimny é exatamente o que procuro." },

  { ad: "Sherco SE 300 Factory", name: "Bruno Sartori", email: "bruno.sartori@exemplo.com.br",
    phone: "(62) 99411-6655", offered_value: 79_000, days_after: 8,
    message: "Corro enduro amador. Quantas horas de motor a moto tem desde a última revisão?" },

  { ad: "Can-Am Maverick X3 Turbo RR", name: "Ricardo Amorim", email: "ricardo.amorim@exemplo.com.br",
    phone: "(71) 98120-9944", offered_value: 392_000, days_after: 6,
    message: "Tenho um UTV menor para dar na troca mais volta em dinheiro. Podemos conversar?" },

  { ad: "Jogo de Pneus BFGoodrich KM3 33\"", name: "Vinícius Rocha", email: "vinicius.rocha@exemplo.com.br",
    phone: "(48) 99730-2211", offered_value: 9_000, days_after: 10, message: nil },

  { ad: "Guincho Elétrico 12.000 lbs", user: "contato@trilhalivre.com.br",
    phone: "(41) 98877-0011", offered_value: 5_000, days_after: 12,
    message: "Levo dois se fizer preço no par. Retiro pessoalmente em São Paulo." },

  { ad: "Bloqueio de Diferencial ARB Air Locker", name: "Marina Coelho", email: "marina.coelho@exemplo.com.br",
    phone: nil, offered_value: 11_500, days_after: 14,
    message: "Serve no eixo traseiro de uma Hilux 2018? Se servir, fecho hoje." },

  { ad: "Barra de LED Auxiliar 52\"", name: "Gustavo Pires", email: "gustavo.pires@exemplo.com.br",
    phone: "(51) 99388-4400", offered_value: 1_150, days_after: 16, message: nil }
].freeze

# ad_images guarda URL, não blob: o PNG vai para public/ e a coluna aponta pra ele.
SEED_IMAGE_DIR = Rails.root.join("public/seed-images")

# Gerar o PNG é o passo caro; várias fotos repetem os mesmos bytes.
def photo_bytes(palette_index)
  @photo_cache ||= {}
  @photo_cache[palette_index] ||= begin
    top, bottom = PALETTES[palette_index % PALETTES.size]
    PlaceholderImage.new(width: 800, height: 600, top: top, bottom: bottom).to_png
  end
end

# Escreve o arquivo uma vez e devolve o caminho público.
def seed_image_url(palette_index, ad_index, photo_index)
  filename = "ad-#{ad_index}-#{photo_index}.png"
  path = SEED_IMAGE_DIR.join(filename)
  File.binwrite(path, photo_bytes(palette_index)) unless path.exist?

  "/seed-images/#{filename}"
end

FileUtils.mkdir_p(SEED_IMAGE_DIR)

admins = ADMINS.map do |attributes|
  admin = Admin.find_or_initialize_by(email: attributes[:email])
  admin.update!(attributes.merge(password: SEED_PASSWORD))
  admin
end
moderator = admins.first

users = USERS.map do |attributes|
  user = User.find_or_initialize_by(email: attributes[:email])
  user.update!(attributes.merge(password: SEED_PASSWORD))
  user
end

categories = CATEGORIES.each_with_object({}) do |attributes, memo|
  category = Category.find_or_initialize_by(slug: attributes[:slug])
  category.update!(position: attributes[:position])
  memo[attributes[:slug]] = category
end

spec_attributes = SPEC_ATTRIBUTES.each_with_object({}) do |attributes, memo|
  record = SpecAttribute.find_or_initialize_by(name: attributes[:name])
  record.update!(attributes)
  memo[attributes[:name]] = record
end

ADS.each_with_index do |attributes, index|
  slug = attributes[:category]
  variants = DESCRIPTIONS.fetch(slug)
  published = index.days.ago

  ad = Ad.find_or_initialize_by(title: attributes[:title])
  ad.assign_attributes(
    year: attributes[:year],
    # DECIMAL em reais: o seed não converte mais para centavos.
    price: attributes[:price],
    city: attributes[:city],
    state: attributes[:state],
    badge: attributes[:badge],
    category: categories.fetch(slug),
    user: users[index % users.size],
    description: format(variants[index % variants.size], title: attributes[:title]),
    # Seed nasce moderado: o portal precisa ter o que mostrar.
    status: :approved,
    admin: moderator,
    reviewed_at: published,
    # Escalona a publicação para a ordenação "mais recentes" fazer sentido.
    published_at: published
  )

  # As fotos entram antes do save: anúncio aprovado só é válido com 3 a 10.
  if ad.ad_images.empty?
    PHOTOS_PER_AD.times do |photo_index|
      ad.ad_images.build(
        file_url: seed_image_url(index + photo_index, index, photo_index),
        sort_order: photo_index
      )
    end
  end

  ad.save!

  # Lado "Value" do EAV, uma linha por especificação.
  CATEGORY_SPECS.fetch(slug).merge(attributes[:specs]).each do |name, value|
    spec_attribute = spec_attributes.fetch(name)
    record = TechnicalSpecValue.find_or_initialize_by(ad_id: ad.id, attribute_id: spec_attribute.id)
    record.update!(value: value.to_s)
  end
end

users_by_email = users.index_by(&:email)
ads_by_title = Ad.where(title: PROPOSALS.map { |attributes| attributes[:ad] }).index_by(&:title)

PROPOSALS.each do |attributes|
  ad = ads_by_title.fetch(attributes[:ad])
  # Quem enviou logado vira o user da proposta; anônimo fica com user_id nulo.
  sender = attributes[:user] && users_by_email.fetch(attributes[:user])

  # O par (anúncio, e-mail) é a chave natural: rodar o seed de novo não duplica.
  proposal = Proposal.find_or_initialize_by(ad_id: ad.id, email: sender&.email || attributes[:email])
  # O min segura a data no presente mesmo se ADS for reordenado e o anúncio
  # passar a ser mais novo que a proposta.
  received_at = [ ad.published_at + attributes[:days_after].days, Time.current ].min

  proposal.update!(
    user: sender,
    name: sender&.name || attributes[:name],
    phone: attributes[:phone],
    # DECIMAL em reais, como o preço do anúncio.
    offered_value: attributes[:offered_value],
    message: attributes[:message],
    # Escalonar a chegada faz a ordenação do painel do anunciante ter sentido.
    created_at: received_at,
    updated_at: received_at
  )
end

puts "Seed: #{Category.count} categorias, #{SpecAttribute.count} atributos, " \
     "#{Admin.count} moderadores, #{User.count} anunciantes, " \
     "#{Ad.count} anúncios (#{Ad.published.count} aprovados), " \
     "#{AdImage.count} fotos, #{TechnicalSpecValue.count} especificações, " \
     "#{Proposal.count} propostas (#{Proposal.where(user: nil).count} anônimas)."
