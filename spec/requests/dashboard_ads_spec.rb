require "rails_helper"

RSpec.describe "Meus Anúncios", type: :request do
  let(:user) { create(:user) }
  let(:vehicles) { create(:category, :vehicles) }

  before { sign_in(user) }

  describe "GET /anunciante/anuncios" do
    it "responde com sucesso" do
      get account_ads_path

      expect(response).to have_http_status(:ok)
    end

    it "não deixa nenhuma chave de tradução sem valor" do
      create(:ad, user: user, category: vehicles)
      create(:ad, :pending, user: user, category: vehicles)

      get account_ads_path

      expect(response.body).not_to include("translation missing")
    end

    it "lista os anúncios do próprio anunciante" do
      mine = create(:ad, user: user, category: vehicles, title: "Meu Jipe")

      get account_ads_path

      expect(response.body).to include(mine.title)
    end

    it "não mostra anúncio de outro anunciante" do
      create(:ad, user: create(:user), category: vehicles, title: "Jipe alheio")

      get account_ads_path

      expect(response.body).not_to include("Jipe alheio")
    end

    # O ponto da página: anúncio parado na moderação não some, aparece marcado.
    it "mostra também o anúncio que ainda não foi aprovado" do
      waiting = create(:ad, :pending, user: user, category: vehicles, title: "Aguardando")

      get account_ads_path

      expect(response.body).to include(waiting.title)
      expect(response.body).to include(I18n.t("ads.statuses.pending"))
    end

    it "explica por que o anúncio rejeitado não está no ar" do
      create(:ad, :rejected, user: user, category: vehicles)

      get account_ads_path

      expect(response.body).to include(I18n.t("dashboard.ads_index.hints.rejected"))
    end

    it "filtra pela situação pedida" do
      create(:ad, user: user, category: vehicles, title: "Jipe aprovado")
      create(:ad, :pending, user: user, category: vehicles, title: "Jipe pendente")

      get account_ads_path(status: "pending")

      expect(response.body).to include("Jipe pendente")
      expect(response.body).not_to include("Jipe aprovado")
    end

    it "mostra tudo quando a situação pedida é desconhecida" do
      create(:ad, user: user, category: vehicles, title: "Jipe aprovado")
      create(:ad, :pending, user: user, category: vehicles, title: "Jipe pendente")

      get account_ads_path(status: "inventado")

      expect(response.body).to include("Jipe aprovado").and include("Jipe pendente")
    end

    it "só oferece o link do portal para anúncio aprovado" do
      create(:ad, :pending, user: user, category: vehicles)

      get account_ads_path

      expect(response.body).to include(I18n.t("dashboard.ads_index.not_public"))
    end
  end

  describe "GET /anunciante/anuncios/novo" do
    it "responde com sucesso" do
      get new_account_ad_path

      expect(response).to have_http_status(:ok)
    end

    it "não deixa nenhuma chave de tradução sem valor" do
      get new_account_ad_path

      expect(response.body).not_to include("translation missing")
    end

    it "já vem com a cidade e o estado do cadastro" do
      get new_account_ad_path

      expect(response.body).to include(%(value="#{user.city}"))
    end
  end

  describe "POST /anunciante/anuncios" do
    let(:photo_urls) { (1..Ad::IMAGE_COUNT.min).map { |n| "/seed-images/foto-#{n}.png" }.join("\n") }
    let(:valid_attributes) do
      { title: "Jeep Wrangler de Teste", category_id: vehicles.id, price: "45.000,50",
        year: 2019, city: "Curitiba", state: "PR", description: "Bem conservado." }
    end

    # Chaves explícitas na chamada: com o keyword `photos:` na assinatura, um
    # hash sem chaves viraria keyword argument em vez de posicional.
    def submit(overrides = {}, photos: photo_urls)
      post account_ads_path, params: { ad: valid_attributes.merge(overrides), photo_urls: photos }
    end

    it "cria o anúncio do próprio anunciante" do
      expect { submit }.to change(user.ads, :count).by(1)
    end

    it "entra na fila de moderação, não no portal" do
      submit

      expect(Ad.last).to be_pending
      expect(Ad.published).to be_empty
    end

    it "aceita o preço no formato brasileiro" do
      # "45.000,50" com o ponto de milhar; sem tratar, viraria 45.
      submit

      expect(Ad.last.price).to eq(45_000.50)
    end

    it "guarda as fotos na ordem das linhas" do
      submit

      expect(Ad.last.ad_images.ordered.pluck(:sort_order)).to eq((0...Ad::IMAGE_COUNT.min).to_a)
    end

    it "redireciona para a lista com aviso de moderação" do
      submit

      expect(response).to redirect_to(account_ads_path)
    end

    it "recusa menos fotos que o mínimo, que a moderação exigiria depois" do
      expect { submit(photos: "/seed-images/unica.png") }.not_to change(Ad, :count)
    end

    it "explica por que recusou" do
      submit(photos: "")

      expect(response.body).to include(I18n.t("activerecord.errors.models.ad.attributes.ad_images.invalid_count",
                                              min: Ad::IMAGE_COUNT.min, max: Ad::IMAGE_COUNT.max))
    end

    it "recusa preço zerado" do
      expect { submit({ price: "0" }) }.not_to change(Ad, :count)
    end

    it "devolve o formulário com 422 quando algo falha" do
      submit({ title: "" })

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "ignora um user_id vindo do formulário" do
      other = create(:user)

      post account_ads_path, params: { ad: valid_attributes.merge(user_id: other.id), photo_urls: photo_urls }

      expect(Ad.last.user).to eq(user)
    end
  end

  it "exige sessão" do
    delete logout_path

    get account_ads_path

    expect(response).to redirect_to(login_path)
  end

  it "exige sessão para publicar" do
    delete logout_path

    get new_account_ad_path

    expect(response).to redirect_to(login_path)
  end
end
