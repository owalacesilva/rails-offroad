require "rails_helper"

RSpec.describe "Recado da moderação", type: :request do
  let(:admin) { create(:admin) }
  let(:user) { create(:user) }
  let(:ad) { create(:ad, :pending, user: user, image_count: 3) }

  describe "rejeição" do
    before { sign_in_admin(admin) }

    it "guarda o motivo" do
      patch reject_admin_ad_path(ad), params: { note: "Fotos desfocadas." }

      expect(ad.reload.moderation_note).to eq("Fotos desfocadas.")
    end

    it "rejeita o anúncio" do
      patch reject_admin_ad_path(ad), params: { note: "Fotos desfocadas." }

      expect(ad.reload).to be_rejected
    end

    # A fila pede o texto pelo formulário; sem ele o campo fica nulo em vez de
    # gravar string vazia.
    it "aceita rejeição sem motivo, deixando o campo nulo" do
      patch reject_admin_ad_path(ad), params: { note: "" }

      expect(ad.reload.moderation_note).to be_nil
    end

    it "oferece o formulário de motivo na fila" do
      ad

      get admin_ads_path(status: "pending")

      expect(response.body).to include(I18n.t("admin.ads.reject_modal.title"), 'name="note"')
    end

    # Aprovar não passa recado: não há o que corrigir.
    it "não pede motivo para aprovar" do
      patch approve_admin_ad_path(ad)

      expect(ad.reload.moderation_note).to be_nil
    end
  end

  describe "o anunciante vê o recado" do
    before do
      ad.reject(admin, note: "Fotos desfocadas. Reenvie com melhor qualidade.")
      sign_in(user)
    end

    it "mostra o texto no painel" do
      get account_ads_path

      expect(response.body).to include("Fotos desfocadas. Reenvie com melhor qualidade.")
    end

    it "identifica de onde veio o recado" do
      get account_ads_path

      expect(response.body).to include(I18n.t("dashboard.ads_index.moderation_note"))
    end

    # Recado de moderação anterior não polui um anúncio que já foi aprovado.
    it "some quando o anúncio é aprovado" do
      ad.approve(admin)

      get account_ads_path

      expect(response.body).not_to include("Fotos desfocadas. Reenvie com melhor qualidade.")
    end

    it "avisa quantas fotos foram bloqueadas" do
      ad.ad_images.first.update!(blocked_at: Time.current)

      get account_ads_path

      expect(response.body).to include(I18n.t("dashboard.ads_index.blocked_images", count: 1))
    end
  end
end
