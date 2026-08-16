require "rails_helper"

RSpec.describe AdsHelper, type: :helper do
  describe "#ad_price" do
    it "formata em reais sem centavos usando os separadores do pt-BR" do
      expect(helper.ad_price(389_900)).to eq("R$ 389.900")
    end

    it "segue os separadores do locale em en-US" do
      I18n.with_locale(:"en-US") do
        expect(helper.ad_price(389_900)).to eq("R$389,900")
      end
    end

    # Exemplo de mock com Mocha (substitui o rspec-mocks neste projeto).
    it "delega a formatação para o number_to_currency do Rails" do
      helper.expects(:number_to_currency)
            .with(389_900, unit: "R$", precision: 0)
            .returns("R$ 389.900")

      expect(helper.ad_price(389_900)).to eq("R$ 389.900")
    end
  end

  describe "#whatsapp_url" do
    let(:user) { create(:user, phone: "5541988770011") }
    let(:ad) { create(:ad, title: "Jeep Wrangler Rubicon", user: user) }

    it "usa o telefone do anunciante" do
      expect(helper.whatsapp_url(ad)).to start_with("https://wa.me/5541988770011?text=")
    end

    it "escapa o título dentro da mensagem" do
      expect(helper.whatsapp_url(ad)).to include(CGI.escape(ad.title))
    end
  end

  describe "#specification_label" do
    it "traduz a chave conhecida" do
      expect(helper.specification_label("mileage_km")).to eq("Quilometragem")
    end

    it "humaniza a chave desconhecida em vez de dizer translation missing" do
      expect(helper.specification_label("torque_maximo")).to eq("Torque maximo")
    end
  end

  describe "#specification_value" do
    it "acrescenta unidade e separador de milhar à quilometragem" do
      expect(helper.specification_value("mileage_km", 48_000)).to eq("48.000 km")
    end

    it "devolve o valor cru nas demais chaves" do
      expect(helper.specification_value("engine", "3.6 V6")).to eq("3.6 V6")
    end
  end

  describe "#paginated_page_numbers" do
    it "numera todas as páginas quando são poucas" do
      pagination = stub(total_pages: 4)

      expect(helper.paginated_page_numbers(pagination)).to eq([ 1, 2, 3, 4 ])
    end

    it "some com a régua numerada quando são muitas" do
      pagination = stub(total_pages: AdsHelper::MAX_NUMBERED_PAGES + 1)

      expect(helper.paginated_page_numbers(pagination)).to be_empty
    end
  end
end
