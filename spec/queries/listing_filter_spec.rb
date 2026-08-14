require "rails_helper"

RSpec.describe ListingFilter do
  let(:vehicles) { create(:category, :vehicles) }
  let(:parts) { create(:category, :parts) }

  let!(:wrangler) do
    create(:listing, category: vehicles, city: "Curitiba", state: "PR",
                     price_cents: 38_990_000, year: 2019, published_at: 1.day.ago)
  end

  let!(:hilux) do
    create(:listing, category: vehicles, city: "São Paulo", state: "SP",
                     price_cents: 34_990_000, year: 2021, published_at: 3.days.ago)
  end

  let!(:snorkel) do
    create(:listing, :without_year, category: parts, city: "Curitiba", state: "PR",
                                    price_cents: 289_000, published_at: 2.days.ago)
  end

  def filtered(params = {})
    described_class.new(params).results
  end

  describe "filtros" do
    it "sem parâmetro devolve tudo" do
      expect(filtered).to contain_exactly(wrangler, hilux, snorkel)
    end

    it "filtra por slug de categoria" do
      expect(filtered(category: "pecas-acessorios")).to contain_exactly(snorkel)
    end

    it "filtra por estado" do
      expect(filtered(state: "SP")).to contain_exactly(hilux)
    end

    it "normaliza o estado para maiúsculas" do
      expect(filtered(state: "sp")).to contain_exactly(hilux)
    end

    it "filtra por cidade" do
      expect(filtered(city: "Curitiba")).to contain_exactly(wrangler, snorkel)
    end

    it "combina estado e cidade" do
      expect(filtered(state: "PR", city: "Curitiba")).to contain_exactly(wrangler, snorkel)
    end

    it "descarta cidade que não pertence ao estado escolhido" do
      # Sem isso o usuário veria zero resultados sem entender por quê.
      expect(filtered(state: "SP", city: "Curitiba")).to contain_exactly(hilux)
    end

    it "ignora categoria inexistente devolvendo vazio" do
      expect(filtered(category: "nao-existe")).to be_empty
    end
  end

  describe "ordenação" do
    it "usa mais recentes por padrão" do
      expect(filtered.to_a).to eq([ wrangler, snorkel, hilux ])
    end

    it "ordena por menor preço" do
      expect(filtered(sort: "price_asc").to_a).to eq([ snorkel, hilux, wrangler ])
    end

    it "ordena por maior preço" do
      expect(filtered(sort: "price_desc").to_a).to eq([ wrangler, hilux, snorkel ])
    end

    it "joga anúncio sem ano para o fim ao ordenar por ano" do
      expect(filtered(sort: "year_desc").to_a).to eq([ hilux, wrangler, snorkel ])
    end

    it "cai no padrão quando o sort é desconhecido" do
      expect(described_class.new({ sort: "'; DROP TABLE listings; --" }).sort).to eq("recent")
    end
  end

  describe "estado do formulário" do
    it "conta os filtros aplicados" do
      expect(described_class.new({ state: "PR", category: "veiculos-4x4" }).applied_count).to eq(2)
    end

    it "não considera a ordenação um filtro" do
      expect(described_class.new({ sort: "price_asc" })).not_to be_applied
    end

    it "lista apenas os estados que têm anúncio" do
      expect(described_class.new({}).state_options).to eq(%w[PR SP])
    end

    it "restringe as cidades ao estado escolhido" do
      expect(described_class.new({ state: "SP" }).city_options).to eq([ "São Paulo" ])
    end
  end
end
