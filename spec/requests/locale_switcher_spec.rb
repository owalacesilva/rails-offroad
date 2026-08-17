require "rails_helper"

RSpec.describe "Troca de idioma", type: :request do
  let(:vehicles) { create(:category, :vehicles) }

  describe "no header do portal" do
    before { create(:ad, category: vehicles) }

    it "oferece os dois idiomas, cada um escrito no próprio idioma" do
      get root_path

      expect(response.body).to include("Português", "English")
    end

    it "não deixa nenhuma chave de tradução sem valor" do
      get root_path

      expect(response.body).not_to include("translation missing")
    end

    it "leva para a mesma página, preservando os filtros da listagem" do
      get ads_path(category: "veiculos-4x4", state: "PR")

      expect(response.body).to include(
        ERB::Util.html_escape("/anuncios?category=veiculos-4x4&locale=en-US&state=PR")
      )
    end

    it "não põe o locale padrão na URL, igual ao default_url_options" do
      get ads_path(category: "veiculos-4x4", locale: "en-US")

      expect(response.body).to include('href="/anuncios?category=veiculos-4x4"')
    end

    # A página do anúncio também é renderizada em resposta ao POST de uma
    # proposta inválida; ali não há rota GET para regerar.
    it "cai na home quando a página vem de um POST" do
      ad = create(:ad, category: vehicles)

      post ad_proposals_path(ad), params: { proposal: { name: "", email: "", offered_value: "" } }

      expect(response.body).to include('href="/?locale=en-US"')
    end
  end

  describe "no menu do painel do anunciante" do
    let(:user) { create(:user) }

    before { sign_in(user) }

    it "oferece a troca de idioma junto das demais funções" do
      get account_path

      expect(response.body).to include("Português", "English")
    end

    it "aplica o idioma escolhido" do
      get account_path(locale: "en-US")

      expect(response.body).to include(I18n.t("dashboard.nav.proposals", locale: :"en-US"))
    end
  end

  describe "no menu da moderação" do
    let(:admin) { create(:admin) }

    before { sign_in_admin(admin) }

    it "oferece a troca de idioma junto das filas" do
      get admin_ads_path

      expect(response.body).to include("Português", "English")
    end

    it "aplica o idioma escolhido" do
      get admin_ads_path(locale: "en-US")

      expect(response.body).to include(I18n.t("admin.ads.statuses.pending", locale: :"en-US"))
    end
  end
end
