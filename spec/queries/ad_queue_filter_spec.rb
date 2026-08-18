require "rails_helper"

RSpec.describe AdQueueFilter do
  let(:vehicles) { create(:category, :vehicles) }
  let(:parts) { create(:category, :parts) }

  def filter(params = {})
    described_class.new(ActionController::Parameters.new(params).permit!)
  end

  describe "situação" do
    # A fila é a razão de o status existir: sem parâmetro, o que importa é o que
    # ainda não foi avaliado.
    it "começa nos pendentes" do
      expect(filter.status).to eq("pending")
    end

    it "abre a fila pedida" do
      expect(filter(status: "rejected").status).to eq("rejected")
    end

    # Status desconhecido na URL não pode virar consulta vazia sem explicação.
    it "cai nos pendentes quando o status é desconhecido" do
      expect(filter(status: "inventado").status).to eq("pending")
    end

    it "aceita a aba de todos, que não é um status de anúncio" do
      approved = create(:ad, category: vehicles)
      pending_ad = create(:ad, :pending, category: vehicles)

      expect(filter(status: "all")).to be_all_statuses
      expect(filter(status: "all").results).to contain_exactly(approved, pending_ad)
    end

    it "recorta pela situação da aba" do
      create(:ad, category: vehicles)
      pending_ad = create(:ad, :pending, category: vehicles)

      expect(filter.results).to eq([ pending_ad ])
    end
  end

  describe "critérios" do
    it "busca no título" do
      jeep = create(:ad, :pending, category: vehicles, title: "Jeep Willys 1962")
      create(:ad, :pending, category: vehicles, title: "Troller T4")

      expect(filter(q: "willys").results).to eq([ jeep ])
    end

    it "filtra por categoria" do
      part = create(:ad, :pending, category: parts)
      create(:ad, :pending, category: vehicles)

      expect(filter(category: parts.slug).results).to eq([ part ])
    end

    it "filtra por UF" do
      paranaense = create(:ad, :pending, category: vehicles, state: "PR")
      create(:ad, :pending, category: vehicles, state: "SP")

      expect(filter(state: "pr").results).to eq([ paranaense ])
    end

    it "ignora UF fora da lista em vez de devolver vazio" do
      ad = create(:ad, :pending, category: vehicles)

      expect(filter(state: "ZZ").results).to eq([ ad ])
    end

    # Nome ou e-mail na mesma caixa: quem modera procura pelos dois sem querer
    # escolher em qual campo digitar.
    it "acha o anunciante pelo nome" do
      mine = create(:ad, :pending, category: vehicles, user: create(:user, name: "Garagem Trilha Livre"))
      # Usuário próprio, e não o padrão da factory: o nome dela é justamente
      # "Garagem Trilha Livre", e os dois anúncios casariam com a busca.
      create(:ad, :pending, category: vehicles, user: create(:user, name: "Oficina do Zulu"))

      expect(filter(advertiser: "trilha").results).to eq([ mine ])
    end

    it "acha o anunciante pelo e-mail" do
      mine = create(:ad, :pending, category: vehicles, user: create(:user, email: "contato@oficina.com.br"))
      create(:ad, :pending, category: vehicles)

      expect(filter(advertiser: "oficina.com.br").results).to eq([ mine ])
    end

    # Digitado em reais, guardado em centavos, como em todo campo de dinheiro.
    it "filtra pela faixa de preço digitada em reais" do
      cheap = create(:ad, :pending, category: vehicles, price: 20_000)
      expensive = create(:ad, :pending, category: vehicles, price: 120_000)

      expect(filter(min_price: "100.000,00").results).to eq([ expensive ])
      expect(filter(max_price: "50.000,00").results).to eq([ cheap ])
    end

    it "ignora preço que não é número" do
      ad = create(:ad, :pending, category: vehicles)

      expect(filter(min_price: "caro").results).to eq([ ad ])
    end

    it "conta os critérios aplicados sem contar a aba nem a ordenação" do
      expect(filter(status: "approved", sort: "price", q: "jeep", state: "PR").applied_count).to eq(2)
    end
  end

  describe "ordenação" do
    it "começa pelo mais recente" do
      expect(filter.sort).to eq("created")
      expect(filter.direction).to eq("desc")
    end

    it "ordena pelo preço" do
      cheap = create(:ad, :pending, category: vehicles, price: 10_000)
      expensive = create(:ad, :pending, category: vehicles, price: 90_000)

      expect(filter(sort: "price", dir: "asc").results).to eq([ cheap, expensive ])
    end

    # Ordenar por coluna de outra tabela é o motivo de o SORTS guardar tabela e
    # coluna em vez de só a coluna.
    it "ordena pelo nome do anunciante" do
      zulu = create(:ad, :pending, category: vehicles, user: create(:user, name: "Zulu Off Road"))
      alfa = create(:ad, :pending, category: vehicles, user: create(:user, name: "Alfa Garagem"))

      expect(filter(sort: "advertiser", dir: "asc").results).to eq([ alfa, zulu ])
    end

    # A posição, e não o nome: o nome da categoria mora nos locales, e ordenar
    # pela coluna do banco daria a ordem de um idioma que ninguém escolheu.
    it "ordena pela posição da categoria" do
      create(:ad, :pending, category: parts)
      create(:ad, :pending, category: vehicles)

      ordered = filter(sort: "category", dir: "asc").results.map { |ad| ad.category.position }

      expect(ordered).to eq(ordered.sort)
    end

    # Coluna desconhecida nunca chega ao ORDER BY.
    it "ignora coluna de ordenação inventada" do
      expect(filter(sort: "; DROP TABLE ads").sort).to eq("created")
    end

    it "ignora direção inventada" do
      expect(filter(dir: "sideways").direction).to eq("desc")
    end

    it "inverte a direção na coluna já ordenada e começa ascendente numa nova" do
      current = filter(sort: "price", dir: "asc")

      expect(current.next_direction("price")).to eq("desc")
      expect(current.next_direction("views")).to eq("asc")
    end
  end

  describe "#to_params" do
    it "leva critérios, aba e ordenação juntos" do
      params = filter(q: "jeep", status: "approved", sort: "price", dir: "asc").to_params

      expect(params).to include(q: "jeep", status: "approved", sort: "price", dir: "asc")
    end

    # O preço volta em reais, que é como foi digitado, e sem o ".0" que um
    # BigDecimal redondo arrastaria para a URL.
    it "devolve o preço em reais, inteiro quando não há centavos" do
      expect(filter(min_price: "45.000,00").to_params[:min_price]).to eq(45_000)
      expect(filter(min_price: "45.000,50").to_params[:min_price]).to eq(45_000.5)
    end

    it "deixa de fora o que não foi preenchido" do
      expect(filter.to_params.keys).to contain_exactly(:status, :sort, :dir)
    end
  end
end
