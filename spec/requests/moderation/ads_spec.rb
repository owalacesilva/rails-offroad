require "rails_helper"

RSpec.describe "Fila de moderação", type: :request do
  let(:admin) { create(:admin) }
  let(:vehicles) { create(:category, :vehicles) }

  before { sign_in_admin(admin) }

  describe "GET /admin/anuncios" do
    it "responde com sucesso" do
      get admin_ads_path

      expect(response).to have_http_status(:ok)
    end

    it "não deixa nenhuma chave de tradução sem valor" do
      create(:ad, :pending, category: vehicles)

      get admin_ads_path

      expect(response.body).not_to include("translation missing")
    end

    it "mostra a fila de pendentes por padrão" do
      pending_ad = create(:ad, :pending, category: vehicles, title: "Jipe pendente")
      create(:ad, category: vehicles, title: "Jipe aprovado")

      get admin_ads_path

      expect(response.body).to include(pending_ad.title)
      expect(response.body).not_to include("Jipe aprovado")
    end

    it "filtra pelo status pedido" do
      create(:ad, :pending, category: vehicles, title: "Jipe pendente")
      approved = create(:ad, category: vehicles, title: "Jipe aprovado")

      get admin_ads_path(status: "approved")

      expect(response.body).to include(approved.title)
      expect(response.body).not_to include("Jipe pendente")
    end

    # Status desconhecido na URL não pode virar consulta vazia sem explicação.
    it "cai na fila padrão quando o status é desconhecido" do
      pending_ad = create(:ad, :pending, category: vehicles, title: "Jipe pendente")

      get admin_ads_path(status: "inventado")

      expect(response.body).to include(pending_ad.title)
    end
  end

  describe "PATCH aprovar" do
    it "aprova e publica o anúncio" do
      ad = create(:ad, :pending, category: vehicles, image_count: 3)

      patch approve_admin_ad_path(ad)

      expect(ad.reload).to have_attributes(status: "approved", admin: admin)
      expect(ad.published_at).to be_present
    end

    it "passa a aparecer no portal depois de aprovado" do
      ad = create(:ad, :pending, category: vehicles, image_count: 3)
      patch approve_admin_ad_path(ad)

      get ad_path(ad)

      expect(response).to have_http_status(:ok)
    end

    it "recusa aprovar sem as fotos mínimas e avisa o moderador" do
      ad = create(:ad, :pending, category: vehicles)

      patch approve_admin_ad_path(ad)

      expect(ad.reload.status).to eq("pending")
      expect(flash[:alert]).to be_present
    end
  end

  describe "PATCH rejeitar" do
    it "rejeita e registra quem avaliou" do
      ad = create(:ad, :pending, category: vehicles)

      patch reject_admin_ad_path(ad)

      expect(ad.reload).to have_attributes(status: "rejected", admin: admin)
    end

    it "tira o anúncio do portal" do
      ad = create(:ad, category: vehicles)

      patch reject_admin_ad_path(ad)
      get ad_path(ad)

      expect(response).to have_http_status(:not_found)
      expect(Ad.published).to be_empty
    end
  end

  describe "sem sessão de moderador" do
    it "não deixa aprovar" do
      delete admin_logout_path
      ad = create(:ad, :pending, category: vehicles, image_count: 3)

      patch approve_admin_ad_path(ad)

      expect(ad.reload.status).to eq("pending")
    end
  end
end
