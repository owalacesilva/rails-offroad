require "rails_helper"

RSpec.describe "Meus Anúncios", type: :request do
  let(:user) { create(:user) }
  let(:vehicles) { create(:category, :vehicles) }

  before { sign_in(user) }

  describe "GET /minha-conta/anuncios" do
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

  it "exige sessão" do
    delete logout_path

    get account_ads_path

    expect(response).to redirect_to(login_path)
  end
end
