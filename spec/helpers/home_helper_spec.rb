require "rails_helper"

RSpec.describe HomeHelper, type: :helper do
  describe "#listing_price" do
    it "formata em reais sem centavos usando os separadores do pt-BR" do
      expect(helper.listing_price(389_900)).to eq("R$ 389.900")
    end

    it "segue os separadores do locale em en-US" do
      I18n.with_locale(:"en-US") do
        expect(helper.listing_price(389_900)).to eq("R$389,900")
      end
    end

    # Exemplo de mock com Mocha (substitui o rspec-mocks neste projeto).
    it "delega a formatação para o number_to_currency do Rails" do
      helper.expects(:number_to_currency)
            .with(389_900, unit: "R$", precision: 0)
            .returns("R$ 389.900")

      expect(helper.listing_price(389_900)).to eq("R$ 389.900")
    end
  end

  describe "#category_name" do
    it "traduz o slug da categoria" do
      expect(helper.category_name("veiculos-4x4")).to eq("Veículos 4x4")
    end
  end

  describe "#category_icon" do
    it "monta um svg inline" do
      expect(helper.category_icon(:truck)).to start_with("<svg").and include("<path")
    end

    it "estoura para um ícone desconhecido" do
      expect { helper.category_icon(:foguete) }.to raise_error(KeyError)
    end
  end
end
