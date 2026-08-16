require "rails_helper"

RSpec.describe "Ads", type: :request do
  let(:vehicles) { create(:category, :vehicles) }
  let(:parts) { create(:category, :parts) }

  let!(:wrangler) { create(:ad, title: "Jeep Wrangler Rubicon", category: vehicles, state: "PR", city: "Curitiba") }
  let!(:snorkel) { create(:ad, title: "Snorkel Safari", category: parts, state: "SP", city: "São Paulo") }

  describe "GET /anuncios" do
    before { get ads_path }

    it "responde com sucesso" do
      expect(response).to have_http_status(:ok)
    end

    it "lista todos os anúncios" do
      expect(response.body).to include(wrangler.title).and include(snorkel.title)
    end

    it "não deixa nenhuma chave de tradução sem valor" do
      expect(response.body).not_to include("translation missing")
    end

    it "renderiza o painel de filtros recolhível" do
      expect(response.body).to include('data-controller="filters"')
    end

    it "renderiza o painel aberto, para funcionar sem JavaScript" do
      panel = response.body[/<div[^>]*data-filters-target="panel"[^>]*>/]

      expect(panel).not_to include("hidden")
    end
  end

  describe "filtros" do
    it "filtra por categoria" do
      get ads_path(category: "pecas-acessorios")

      expect(response.body).to include(snorkel.title)
      expect(response.body).not_to include(wrangler.title)
    end

    it "filtra por estado" do
      get ads_path(state: "PR")

      expect(response.body).to include(wrangler.title)
      expect(response.body).not_to include(snorkel.title)
    end

    it "filtra por cidade" do
      get ads_path(city: "Curitiba")

      expect(response.body).to include(wrangler.title)
      expect(response.body).not_to include(snorkel.title)
    end

    it "mostra o estado vazio quando nada casa" do
      get ads_path(state: "AM")

      expect(response.body).to include(I18n.t("ads.empty.title"))
    end

    it "ignora parâmetro de ordenação desconhecido" do
      get ads_path(sort: "'; DROP TABLE ads; --")

      expect(response).to have_http_status(:ok)
    end
  end

  describe "paginação" do
    before { create_list(:ad, 15, category: vehicles) }

    it "limita a página ao tamanho configurado" do
      get ads_path

      expect(response.body.scan("<article").size).to eq(Pagination::PER_PAGE)
    end

    it "corrige página fora do intervalo em vez de devolver vazio" do
      get ads_path(page: 999)

      expect(response.body).not_to include(I18n.t("ads.empty.title"))
    end

    it "preserva os filtros nos links de página" do
      get ads_path(category: "veiculos-4x4")

      expect(response.body).to include("category=veiculos-4x4&amp;page=2")
    end
  end

  describe "locale" do
    it "responde em en-US quando pedido" do
      get ads_path(locale: "en-US")

      expect(response.body).to include(I18n.t("ads.filters.category", locale: :"en-US"))
    end
  end
end
