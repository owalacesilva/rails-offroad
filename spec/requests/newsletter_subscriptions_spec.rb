require "rails_helper"

RSpec.describe "Newsletter", type: :request do
  describe "POST /newsletter" do
    it "inscreve um visitante anônimo" do
      expect {
        post newsletter_subscription_path, params: { email: "ana@exemplo.com.br", source: "home" }
      }.to change(NewsletterSubscription, :count).by(1)

      expect(flash[:notice]).to eq(I18n.t("newsletter.create.success"))
    end

    # A home é longa: sem a âncora o visitante voltaria ao topo sem ver o aviso.
    it "volta para o bloco da home" do
      post newsletter_subscription_path, params: { email: "ana@exemplo.com.br" }

      expect(response).to redirect_to("#{root_path}#newsletter")
    end

    it "trata reinscrição como sucesso, sem duplicar" do
      create(:newsletter_subscription, email: "ana@exemplo.com.br")

      expect {
        post newsletter_subscription_path, params: { email: "ANA@exemplo.com.br" }
      }.not_to change(NewsletterSubscription, :count)

      expect(flash[:notice]).to eq(I18n.t("newsletter.create.success"))
    end

    it "avisa quando o e-mail não presta" do
      expect {
        post newsletter_subscription_path, params: { email: "nao-e-email" }
      }.not_to change(NewsletterSubscription, :count)

      expect(flash[:alert]).to eq(I18n.t("newsletter.create.failure"))
    end

    it "guarda a origem informada pelo formulário" do
      post newsletter_subscription_path, params: { email: "ana@exemplo.com.br", source: "home" }

      expect(NewsletterSubscription.last.source).to eq("home")
    end
  end
end
