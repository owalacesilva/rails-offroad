require "rails_helper"

RSpec.describe City, type: :model do
  subject { build(:city) }

  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_presence_of(:ibge_code) }
  it { is_expected.to validate_uniqueness_of(:ibge_code).case_insensitive }
  it { is_expected.to validate_inclusion_of(:state).in_array(User::BRAZILIAN_STATES) }

  describe "código do IBGE" do
    it "aceita sete dígitos começando fora do zero" do
      expect(build(:city, ibge_code: "4106902")).to be_valid
    end

    it "recusa código curto" do
      expect(build(:city, ibge_code: "410690")).not_to be_valid
    end

    it "recusa código com letra" do
      expect(build(:city, ibge_code: "41069AB")).not_to be_valid
    end

    # A mesma regra vale no banco, não só no modelo.
    it "é cobrado por check constraint" do
      city = build(:city, ibge_code: "0000000")

      expect { city.save!(validate: false) }.to raise_error(ActiveRecord::StatementInvalid)
    end
  end

  describe "unicidade do nome" do
    # Há cinco "Bom Jesus" no país, mas nenhum estado tem dois.
    it "aceita o mesmo nome em estados diferentes" do
      create(:city, name: "Bom Jesus", state: "PI")

      expect(build(:city, name: "Bom Jesus", state: "RS")).to be_valid
    end

    it "recusa o mesmo nome no mesmo estado" do
      create(:city, name: "Bom Jesus", state: "PI")

      expect(build(:city, name: "Bom Jesus", state: "PI")).not_to be_valid
    end
  end

  describe "escopos" do
    it "ordered ordena por UF e depois por nome" do
      curitiba = create(:city, :curitiba)
      sao_paulo = create(:city, :sao_paulo)

      expect(described_class.ordered).to eq([ curitiba, sao_paulo ])
    end

    it "by_state filtra pela UF" do
      curitiba = create(:city, :curitiba)
      create(:city, :sao_paulo)

      expect(described_class.by_state("PR")).to eq([ curitiba ])
    end

    # A collation do MySQL é indiferente a caixa e a acento: nenhuma coluna
    # normalizada é necessária para "sao paulo" achar "São Paulo".
    it "matching encontra sem acento e sem caixa" do
      sao_paulo = create(:city, :sao_paulo)

      expect(described_class.matching("sao pau")).to eq([ sao_paulo ])
    end

    it "matching ancora no começo do nome" do
      create(:city, :sao_paulo)

      expect(described_class.matching("paulo")).to be_empty
    end
  end

  describe "#location" do
    it "junta nome e UF" do
      expect(build(:city, :curitiba).location).to eq("Curitiba, PR")
    end
  end
end
