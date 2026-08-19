require "rails_helper"

RSpec.describe Pagseguro do
  let(:order) do
    described_class::Order.new(
      reference_id: "PREMIUM-abc123", amount_cents: 4_990, item_name: "Plano Premium",
      redirect_url: "https://portal.test/anunciante/premium",
      notification_url: "https://portal.test/pagseguro/notificacoes"
    )
  end

  def stub_checkout(host: "https://sandbox.api.pagseguro.com", status: 200, body: checkout_body)
    stub_request(:post, "#{host}/checkouts")
      .to_return(status: status, body: body.to_json, headers: { "Content-Type" => "application/json" })
  end

  def checkout_body(links: [ { "rel" => "PAY", "href" => "https://pagamento.pagseguro.uol.com.br/pagamento?code=XYZ" } ])
    { "id" => "CHEC_123", "status" => "ACTIVE", "links" => links }
  end

  describe ".build" do
    it "não existe sem token no ambiente" do
      expect(described_class.build({})).to be_nil
      expect(described_class.configured?({})).to be(false)
    end

    it "existe com token" do
      expect(described_class.build("PAGSEGURO_TOKEN" => "tok")).to be_a(described_class)
      expect(described_class.configured?("PAGSEGURO_TOKEN" => "tok")).to be(true)
    end

    # Espaço em branco é ausência: variável exportada vazia não configura nada.
    it "trata token em branco como ausente" do
      expect(described_class.build("PAGSEGURO_TOKEN" => "   ")).to be_nil
    end
  end

  describe "ambiente" do
    it "fala com o sandbox quando o ambiente não é dito" do
      request = stub_checkout(host: "https://sandbox.api.pagseguro.com")

      described_class.new("tok").create_checkout(order)

      expect(request).to have_been_requested
    end

    it "fala com produção quando pedido" do
      request = stub_checkout(host: "https://api.pagseguro.com")

      described_class.new("tok", "production").create_checkout(order)

      expect(request).to have_been_requested
    end

    # Errar a grafia tem de custar uma cobrança que não acontece, nunca uma que
    # acontece sem querer.
    it "cai no sandbox quando o ambiente é desconhecido" do
      request = stub_checkout(host: "https://sandbox.api.pagseguro.com")

      described_class.new("tok", "produção").create_checkout(order)

      expect(request).to have_been_requested
    end
  end

  describe "#create_checkout" do
    it "devolve o link marcado com rel PAY" do
      stub_checkout

      expect(described_class.new("tok").create_checkout(order))
        .to eq("https://pagamento.pagseguro.uol.com.br/pagamento?code=XYZ")
    end

    it "manda o token no Authorization e o pedido em JSON" do
      request = stub_checkout

      described_class.new("tok").create_checkout(order)

      expect(request.with { |sent|
        payload = JSON.parse(sent.body)

        sent.headers["Authorization"] == "Bearer tok" &&
          payload["reference_id"] == "PREMIUM-abc123" &&
          payload["items"] == [ { "name" => "Plano Premium", "quantity" => 1, "unit_amount" => 4_990 } ] &&
          payload["notification_urls"] == [ "https://portal.test/pagseguro/notificacoes" ]
      }).to have_been_requested
    end

    # O portal não guarda CPF, e a API exige tax_id junto com o nome quando o
    # objeto `customer` vem — então ele não vem, e a página do PagBank pergunta.
    it "não manda dados do cliente" do
      request = stub_checkout

      described_class.new("tok").create_checkout(order)

      expect(request.with { |sent| !JSON.parse(sent.body).key?("customer") }).to have_been_requested
    end

    it "devolve nil quando o PagBank recusa" do
      stub_checkout(status: 401, body: { error: "unauthorized" })

      expect(described_class.new("tok").create_checkout(order)).to be_nil
    end

    # Resposta 200 sem link de pagamento não é sucesso: não há para onde mandar
    # o navegador.
    it "devolve nil quando a resposta não traz o link PAY" do
      stub_checkout(body: checkout_body(links: [ { "rel" => "SELF", "href" => "https://api.pagseguro.com/checkouts/CHEC_123" } ]))

      expect(described_class.new("tok").create_checkout(order)).to be_nil
    end

    # O endereço vira um redirect para fora do portal. Exigir https recusa de
    # saída um "javascript:" que aparecesse no lugar do link.
    it "recusa link de pagamento que não seja https" do
      stub_checkout(body: checkout_body(links: [ { "rel" => "PAY", "href" => "javascript:alert(1)" } ]))

      expect(described_class.new("tok").create_checkout(order)).to be_nil
    end

    it "recusa link de pagamento em http puro" do
      stub_checkout(body: checkout_body(links: [ { "rel" => "PAY", "href" => "http://pagamento.pagseguro.uol.com.br/x" } ]))

      expect(described_class.new("tok").create_checkout(order)).to be_nil
    end

    it "devolve nil quando o gateway está fora do ar" do
      stub_request(:post, "https://sandbox.api.pagseguro.com/checkouts").to_timeout

      expect(described_class.new("tok").create_checkout(order)).to be_nil
    end

    it "devolve nil quando a resposta não é JSON" do
      stub_request(:post, "https://sandbox.api.pagseguro.com/checkouts").to_return(status: 200, body: "<html>")

      expect(described_class.new("tok").create_checkout(order)).to be_nil
    end
  end

  describe "#authentic?" do
    let(:gateway) { described_class.new("tok") }
    let(:payload) { '{"reference_id":"PREMIUM-abc123"}' }

    it "aceita o hash do token com o corpo" do
      signature = OpenSSL::Digest::SHA256.hexdigest("tok-#{payload}")

      expect(gateway.authentic?(payload, signature)).to be(true)
    end

    it "recusa assinatura de outro token" do
      signature = OpenSSL::Digest::SHA256.hexdigest("outro-#{payload}")

      expect(gateway.authentic?(payload, signature)).to be(false)
    end

    # Um espaço a mais no corpo muda o hash: é por isso que a controller usa
    # request.raw_post e não os params reserializados.
    it "recusa quando o corpo mudou" do
      signature = OpenSSL::Digest::SHA256.hexdigest("tok-#{payload}")

      expect(gateway.authentic?("#{payload} ", signature)).to be(false)
    end

    it "recusa assinatura ausente" do
      expect(gateway.authentic?(payload, nil)).to be(false)
      expect(gateway.authentic?(payload, "")).to be(false)
    end
  end
end
