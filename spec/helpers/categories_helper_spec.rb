require "rails_helper"

RSpec.describe CategoriesHelper, type: :helper do
  describe "#category_icon" do
    it "monta um svg inline" do
      expect(helper.category_icon(:truck)).to start_with("<svg").and include("<path")
    end

    it "estoura para um ícone desconhecido" do
      expect { helper.category_icon(:foguete) }.to raise_error(KeyError)
    end
  end

  describe "#category_icon_for" do
    it "escolhe o ícone pelo slug da categoria" do
      expect(helper.category_icon_for("motos-quadriciclos")).to include(CategoriesHelper::CATEGORY_ICON_PATHS[:bike].first)
    end

    it "cai no ícone genérico para slug sem mapeamento" do
      expect(helper.category_icon_for("categoria-nova")).to include(CategoriesHelper::CATEGORY_ICON_PATHS[:wrench].first)
    end
  end
end
