require "rails_helper"

RSpec.describe "Home", type: :request do
  let(:vehicles) { create(:category, :vehicles) }

  describe "GET /" do
    before do
      create_list(:ad, 6, category: vehicles)
      get root_path
    end

    it "responde com sucesso" do
      expect(response).to have_http_status(:ok)
    end

    it "mostra apenas os anúncios mais recentes na vitrine" do
      expect(response.body.scan("<article").size).to eq(HomeController::RECENT_LIMIT)
    end

    it "não deixa nenhuma chave de tradução sem valor" do
      expect(response.body).not_to include("translation missing")
    end

    it "leva o card de categoria para a listagem já filtrada" do
      expect(response.body).to include(ads_path(category: "veiculos-4x4"))
    end
  end

  describe "busca do hero" do
    before { create(:ad, category: vehicles, title: "Suzuki Jimny Sierra 1.5 4x4") }

    it "envia a busca para a listagem" do
      get root_path

      expect(response.body).to include('action="/anuncios"', 'name="q"', 'name="category"')
    end

    it "oferece atalhos que são buscas de verdade" do
      get root_path

      expect(response.body).to include(ads_path(q: "Jimny"))
    end

    # Afirmar só a presença passaria mesmo sem filtro nenhum, porque os dois
    # anúncios cabem na primeira página: a ausência do outro é a prova.
    it "o atalho filtra a listagem de verdade" do
      create(:ad, category: vehicles, title: "Ford Ranger Raptor 2.0")

      get ads_path(q: "Jimny")

      expect(response.body).to include("Suzuki Jimny Sierra 1.5 4x4")
      expect(response.body).not_to include("Ford Ranger Raptor 2.0")
    end
  end

  describe "seleção de locale" do
    it "usa pt-BR por padrão" do
      get root_path

      expect(response.body).to include(I18n.t("home.ads.title", locale: :"pt-BR"))
    end

    it "aceita en-US pelo parâmetro da URL" do
      get root_path(locale: "en-US")

      expect(response.body).to include(I18n.t("home.ads.title", locale: :"en-US"))
    end

    it "ignora o Accept-Language do navegador e mantém o padrão" do
      # O portal é brasileiro: só ?locale= tira a interface do pt-BR.
      get root_path, headers: { "Accept-Language" => "en-US,en;q=0.9" }

      expect(response.body).to include(I18n.t("home.ads.title", locale: :"pt-BR"))
    end

    it "atende o ?locale= mesmo com o navegador pedindo outra coisa" do
      get root_path(locale: "en-US"), headers: { "Accept-Language" => "pt-BR,pt;q=0.9" }

      expect(response.body).to include(I18n.t("home.ads.title", locale: :"en-US"))
    end

    it "ignora locale não suportado e cai no padrão" do
      get root_path(locale: "xx-YY")

      expect(response.body).to include(I18n.t("home.ads.title", locale: :"pt-BR"))
    end

    it "não oferece :en, que existe apenas como base de fallback de en-US" do
      get root_path(locale: "en")

      expect(response.body).to include(I18n.t("home.ads.title", locale: :"pt-BR"))
    end
  end
end
