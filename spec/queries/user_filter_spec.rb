require "rails_helper"

RSpec.describe UserFilter do
  def filter(params = {})
    described_class.new(ActionController::Parameters.new(params).permit!)
  end

  describe "filtros" do
    it "sem parâmetro nenhum devolve todos" do
      create_list(:user, 3)

      expect(filter.results.count).to eq(3)
    end

    it "filtra por nome, sem diferenciar caixa" do
      wanted = create(:user, name: "Garagem Trilha Livre")
      create(:user, name: "Outra Coisa")

      expect(filter(name: "trilha").results).to eq([ wanted ])
    end

    it "filtra por e-mail" do
      wanted = create(:user, email: "achado@exemplo.com.br")
      create(:user, email: "outro@exemplo.com.br")

      expect(filter(email: "achado").results).to eq([ wanted ])
    end

    # A coluna guarda só dígitos; o filtro tira a máscara antes de comparar.
    it "filtra por telefone ignorando a máscara digitada" do
      wanted = create(:user, phone: "5541988770011")
      create(:user, phone: "5511977660022")

      expect(filter(phone: "(41) 9 8877").results).to eq([ wanted ])
    end

    it "filtra por situação" do
      blocked = create(:user, status: :blocked)
      create(:user)

      expect(filter(status: "blocked").results).to eq([ blocked ])
    end

    it "ignora situação que não existe" do
      create_list(:user, 2)

      expect(filter(status: "inventada").results.count).to eq(2)
    end

    it "filtra por quantidade mínima de anúncios" do
      busy = create(:user)
      create_list(:ad, 3, user: busy)
      create(:user)

      expect(filter(min_ads: "3").results).to eq([ busy ])
    end

    it "filtra por quantidade máxima de anúncios" do
      quiet = create(:user)
      busy = create(:user)
      create_list(:ad, 3, user: busy)

      expect(filter(max_ads: "0").results).to eq([ quiet ])
    end

    it "combina faixa mínima e máxima" do
      create(:user)
      middle = create(:user)
      create_list(:ad, 2, user: middle)
      busy = create(:user)
      create_list(:ad, 5, user: busy)

      expect(filter(min_ads: "1", max_ads: "3").results).to eq([ middle ])
    end

    it "combina critérios diferentes" do
      wanted = create(:user, name: "Garagem Trilha", status: :blocked)
      create(:user, name: "Garagem Trilha")
      create(:user, name: "Outra", status: :blocked)

      expect(filter(name: "trilha", status: "blocked").results).to eq([ wanted ])
    end

    # % e _ digitados não podem virar curinga.
    it "escapa curinga digitado" do
      create(:user, name: "Garagem Trilha")

      expect(filter(name: "%").results).to be_empty
    end
  end

  describe "contagem de filtros aplicados" do
    it "conta zero sem filtro" do
      expect(filter).not_to be_applied
    end

    it "conta cada critério preenchido" do
      expect(filter(name: "a", status: "active", min_ads: "1").applied_count).to eq(3)
    end

    # Ordenação sempre tem valor e não restringe nada: não entra na conta.
    it "não conta a ordenação" do
      expect(filter(sort: "name", dir: "asc")).not_to be_applied
    end
  end

  describe "ordenação" do
    it "ordena pela coluna pedida" do
      last = create(:user, name: "Zulu")
      first = create(:user, name: "Alfa")

      expect(filter(sort: "name", dir: "asc").results).to eq([ first, last ])
    end

    it "inverte com a direção" do
      last = create(:user, name: "Zulu")
      first = create(:user, name: "Alfa")

      expect(filter(sort: "name", dir: "desc").results).to eq([ last, first ])
    end

    it "ordena por quantidade de anúncios" do
      quiet = create(:user)
      busy = create(:user)
      create_list(:ad, 2, user: busy)

      expect(filter(sort: "ads", dir: "desc").results).to eq([ busy, quiet ])
    end

    # A coluna nunca vem do parâmetro: chave desconhecida cai no padrão em vez
    # de ser interpolada no ORDER BY.
    it "ignora coluna inventada" do
      expect(filter(sort: "'; DROP TABLE users; --").sort).to eq(described_class::DEFAULT_SORT)
    end

    it "ignora direção inventada" do
      expect(filter(dir: "sideways").direction).to eq(described_class::DEFAULT_DIRECTION)
    end

    it "next_direction começa em ascendente numa coluna nova" do
      expect(filter(sort: "name", dir: "asc").next_direction("email")).to eq("asc")
    end

    it "next_direction inverte na coluna já ordenada" do
      expect(filter(sort: "name", dir: "asc").next_direction("name")).to eq("desc")
    end
  end

  describe "#to_params" do
    it "carrega o que está preenchido" do
      params = filter(name: "trilha", sort: "ads", dir: "asc").to_params

      expect(params).to include(name: "trilha", sort: "ads", dir: "asc")
    end

    it "não carrega critério vazio" do
      expect(filter(name: "").to_params).not_to have_key(:name)
    end
  end
end
