require "rails_helper"

# A notificação é a única coisa que concede Premium: voltar do checkout traz só
# um navegador, e navegador se falsifica com uma URL.
RSpec.describe "Notificação do PagSeguro", type: :request do
  let(:user) { create(:user) }
  let(:subscription) { create(:subscription, user: user) }

  def payload_for(reference_id, status: "PAID")
    { reference_id: reference_id, charges: [ { id: "CHAR_1", status: status } ] }.to_json
  end

  # Como o PagBank chama: corpo cru em JSON e a assinatura no cabeçalho.
  def notify(payload, signature: PagseguroEnvironment.signature(payload))
    post pagseguro_notifications_path, params: payload,
         headers: { "CONTENT_TYPE" => "application/json", "x-authenticity-token" => signature }
  end

  describe "sem PAGSEGURO_TOKEN no ambiente" do
    it "não existe" do
      notify(payload_for(subscription.gateway_reference), signature: "qualquer")

      expect(response).to have_http_status(:not_found)
      expect(subscription.reload).to be_pending
    end
  end

  describe "com assinatura válida", :pagseguro do
    it "confirma o pagamento e concede o Premium" do
      notify(payload_for(subscription.gateway_reference))

      expect(response).to have_http_status(:ok)
      expect(subscription.reload).to be_paid
      expect(user.reload.premium?).to be(true)
    end

    it "registra a recusa sem conceder Premium" do
      notify(payload_for(subscription.gateway_reference, status: "DECLINED"))

      expect(response).to have_http_status(:ok)
      expect(subscription.reload).to be_declined
      expect(user.reload.premium?).to be(false)
    end

    # O PagBank reenvia o que não respondeu 2xx, e reenviar não faria a linha
    # aparecer: referência desconhecida é 200, não erro.
    it "aceita referência desconhecida sem reclamar" do
      notify(payload_for("PREMIUM-nao-existe"))

      expect(response).to have_http_status(:ok)
    end

    it "aceita notificação sem cobrança" do
      notify({ reference_id: subscription.gateway_reference }.to_json)

      expect(response).to have_http_status(:ok)
      expect(subscription.reload).to be_pending
    end

    # Reenvio não pode conceder um segundo mês.
    it "é idempotente" do
      notify(payload_for(subscription.gateway_reference))
      first = subscription.reload.paid_through

      travel 3.days do
        notify(payload_for(subscription.gateway_reference))

        expect(response).to have_http_status(:ok)
        expect(subscription.reload.paid_through).to eq(first)
      end
    end

    # Sem sessão e sem token de CSRF, como o servidor do PagBank chama.
    it "não exige login nem CSRF" do
      notify(payload_for(subscription.gateway_reference))

      expect(response).to have_http_status(:ok)
    end
  end

  # Sem esta conferência, quem descobrisse a URL concederia Premium a si mesmo
  # com um POST.
  describe "com assinatura inválida", :pagseguro do
    it "recusa assinatura forjada" do
      notify(payload_for(subscription.gateway_reference), signature: "f" * 64)

      expect(response).to have_http_status(:unauthorized)
      expect(subscription.reload).to be_pending
    end

    it "recusa notificação sem assinatura" do
      post pagseguro_notifications_path, params: payload_for(subscription.gateway_reference),
           headers: { "CONTENT_TYPE" => "application/json" }

      expect(response).to have_http_status(:unauthorized)
      expect(subscription.reload).to be_pending
    end

    # A assinatura é do corpo exato: trocar o reference_id depois de assinar
    # invalida o hash.
    it "recusa corpo trocado depois de assinado" do
      signature = PagseguroEnvironment.signature(payload_for(subscription.gateway_reference))

      notify(payload_for("PREMIUM-de-outra-pessoa"), signature: signature)

      expect(response).to have_http_status(:unauthorized)
    end

    it "recusa assinatura de outro token" do
      payload = payload_for(subscription.gateway_reference)

      notify(payload, signature: PagseguroEnvironment.signature(payload, token: "outro-token"))

      expect(response).to have_http_status(:unauthorized)
      expect(subscription.reload).to be_pending
    end
  end
end
