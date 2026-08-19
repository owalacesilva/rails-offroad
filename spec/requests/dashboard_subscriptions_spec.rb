require "rails_helper"

RSpec.describe "Assinatura do Premium", type: :request do
  let(:user) { create(:user) }

  def stub_checkout(status: 200, links: [ { "rel" => "PAY", "href" => "https://pagamento.pagseguro.uol.com.br/pagamento?code=XYZ" } ])
    stub_request(:post, "https://sandbox.api.pagseguro.com/checkouts")
      .to_return(status: status, body: { "id" => "CHEC_1", "links" => links }.to_json,
                 headers: { "Content-Type" => "application/json" })
  end

  # Sem credencial a assinatura não existe para ninguém: é o mesmo desenho dos
  # provedores de login, e é o que mantém uma instalação só de classificado de
  # graça sem botão que daria erro.
  describe "sem PAGSEGURO_TOKEN no ambiente" do
    before { sign_in(user) }

    it "não tem página de assinatura" do
      get account_premium_path

      expect(response).to have_http_status(:not_found)
    end

    it "não tem como criar cobrança" do
      post account_premium_path

      expect(response).to have_http_status(:not_found)
      expect(Subscription.count).to eq(0)
    end

    it "não mostra o item Premium no menu do painel" do
      get account_path

      expect(response.body).not_to include(account_premium_path)
    end
  end

  describe "GET /anunciante/premium", :pagseguro do
    it "exige login" do
      get account_premium_path

      expect(response).to redirect_to(login_path)
    end

    it "mostra o plano e o preço para quem ainda não assinou" do
      sign_in(user)

      get account_premium_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(I18n.t("dashboard.premium.inactive"),
                                      I18n.t("dashboard.premium.pay"), "49,90")
      expect(response.body).not_to include("translation missing")
    end

    it "mostra até quando vale para quem já assinou" do
      subscription = create(:subscription, :paid, user: user)
      sign_in(user)

      get account_premium_path

      expect(response.body).to include(I18n.t("dashboard.premium.active"),
                                      I18n.l(subscription.paid_through, format: :long))
    end

    it "lista as vantagens declaradas na página de planos" do
      sign_in(user)

      get account_premium_path

      features = I18n.t("pages.pricing.plans").find { |plan| plan[:key] == "premium" }[:features]

      expect(response.body).to include(*features.map { |feature| ERB::Util.html_escape(feature) })
    end

    it "aparece no menu do painel" do
      sign_in(user)

      get account_path

      expect(response.body).to include(account_premium_path)
    end

    it "responde também em en-US" do
      sign_in(user)

      get account_premium_path, params: { locale: "en-US" }

      expect(response.body).to include(I18n.t("dashboard.premium.title", locale: :"en-US"))
      expect(response.body).not_to include("translation missing")
    end
  end

  describe "POST /anunciante/premium", :pagseguro do
    before { sign_in(user) }

    it "abre a cobrança e manda o navegador ao PagBank" do
      stub_checkout

      post account_premium_path

      expect(response).to redirect_to("https://pagamento.pagseguro.uol.com.br/pagamento?code=XYZ")
      expect(user.subscriptions.pending.count).to eq(1)
      expect(user.subscriptions.last.amount_cents).to eq(PagesHelper::PLAN_PRICES.fetch("premium"))
    end

    # O nome que vai na fatura não pode depender do idioma escolhido na sessão.
    it "manda o nome do item sempre em pt-BR" do
      request = stub_checkout

      post account_premium_path, params: { locale: "en-US" }

      expect(request.with { |sent|
        JSON.parse(sent.body).dig("items", 0, "name") == I18n.t("dashboard.premium.item", locale: :"pt-BR")
      }).to have_been_requested
    end

    it "manda a URL de notificação do próprio portal" do
      request = stub_checkout

      post account_premium_path

      expect(request.with { |sent|
        JSON.parse(sent.body)["notification_urls"].first.end_with?("/pagseguro/notificacoes")
      }).to have_been_requested
    end

    # Cobrança que não existe no PagBank não pode ficar pendente para sempre na
    # tabela: não há nada do outro lado para confirmá-la.
    it "não deixa cobrança órfã quando o PagBank recusa" do
      stub_checkout(status: 401)

      post account_premium_path

      expect(response).to redirect_to(account_premium_path)
      expect(flash[:alert]).to eq(I18n.t("dashboard.premium.failure"))
      expect(Subscription.count).to eq(0)
    end

    it "não deixa cobrança órfã quando a resposta não traz link de pagamento" do
      stub_checkout(links: [ { "rel" => "SELF", "href" => "https://api.pagseguro.com/x" } ])

      post account_premium_path

      expect(flash[:alert]).to be_present
      expect(Subscription.count).to eq(0)
    end

    # Pagar não é o mesmo que ter pago: o Premium só vem pela notificação
    # assinada, nunca por ter começado o checkout.
    it "não concede Premium ao criar a cobrança" do
      stub_checkout

      post account_premium_path

      expect(user.reload.premium?).to be(false)
    end
  end
end
