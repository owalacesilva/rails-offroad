require "rails_helper"

RSpec.describe "Home", type: :request do
  describe "GET /" do
    before { get root_path }

    it "responde com sucesso" do
      expect(response).to have_http_status(:ok)
    end

    it "monta um card para cada anúncio recente" do
      expect(response.body.scan("<article").size).to eq(HomeController::RECENT_LISTINGS.size)
    end

    it "não deixa nenhuma chave de tradução sem valor" do
      expect(response.body).not_to include("translation missing")
    end
  end

  describe "seleção de locale" do
    it "usa pt-BR por padrão" do
      get root_path

      expect(response.body).to include(I18n.t("home.listings.title", locale: :"pt-BR"))
    end

    it "aceita en-US pelo parâmetro da URL" do
      get root_path(locale: "en-US")

      expect(response.body).to include(I18n.t("home.listings.title", locale: :"en-US"))
    end

    it "aceita en-US pelo cabeçalho Accept-Language" do
      get root_path, headers: { "Accept-Language" => "en-US,en;q=0.9" }

      expect(response.body).to include(I18n.t("home.listings.title", locale: :"en-US"))
    end

    it "ignora locale não suportado e cai no padrão" do
      get root_path(locale: "xx-YY")

      expect(response.body).to include(I18n.t("home.listings.title", locale: :"pt-BR"))
    end
  end
end
