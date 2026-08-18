require "rails_helper"

RSpec.describe AdsHelper, type: :helper do
  # Duas origens convivem: o HTML do editor do formulário e o texto puro com
  # linhas em branco que o seed grava.
  describe "#ad_description" do
    it "mostra o HTML do editor como está" do
      ad = build(:ad, description: "<h3>Motor</h3><ul><li>Pneu novo</li></ul>")

      expect(helper.ad_description(ad)).to eq("<h3>Motor</h3><ul><li>Pneu novo</li></ul>")
    end

    it "transforma linha em branco de texto puro em parágrafo" do
      ad = build(:ad, description: "Bem conservado.\n\nAceito troca.")

      expect(helper.ad_description(ad)).to eq("<p>Bem conservado.</p>\n\n<p>Aceito troca.</p>")
    end

    # O sanitizador já escapou o & na entrada; escapar de novo daria "&amp;amp;".
    it "não escapa duas vezes o texto puro" do
      ad = build(:ad, description: "Motor & câmbio revisados")

      expect(helper.ad_description(ad)).to eq("<p>Motor &amp; câmbio revisados</p>")
    end

    # Defesa em profundidade: update_column passa por fora do setter do modelo,
    # como passaria um INSERT feito na mão ou uma importação antiga.
    it "sanitiza também na exibição" do
      ad = create(:ad)
      ad.update_column(:description, "<p>ok</p><iframe src='x'></iframe>")

      expect(helper.ad_description(ad.reload)).to eq("<p>ok</p>")
    end

    it "não devolve nada quando não há descrição" do
      expect(helper.ad_description(build(:ad, description: nil))).to be_nil
    end
  end

  describe "#ad_price" do
    # Duas casas desde que o valor virou centavo inteiro no banco: os centavos
    # existem de verdade e arredondá-los mostraria um preço que não é o cobrado.
    it "formata em reais com centavos usando os separadores do pt-BR" do
      expect(helper.ad_price(389_900)).to eq("R$ 389.900,00")
    end

    it "mostra os centavos que o valor tem" do
      expect(helper.ad_price(BigDecimal("45000.50"))).to eq("R$ 45.000,50")
    end

    it "segue os separadores do locale em en-US" do
      I18n.with_locale(:"en-US") do
        expect(helper.ad_price(389_900)).to eq("R$389,900.00")
      end
    end

    # Exemplo de mock com Mocha (substitui o rspec-mocks neste projeto).
    it "delega a formatação para o number_to_currency do Rails" do
      helper.expects(:number_to_currency)
            .with(389_900, unit: "R$", precision: 2)
            .returns("R$ 389.900,00")

      expect(helper.ad_price(389_900)).to eq("R$ 389.900,00")
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
end
