require "rails_helper"

RSpec.describe Subscription do
  describe ".open_for" do
    it "abre a cobrança pendente com o valor do plano" do
      subscription = described_class.open_for(create(:user), amount_cents: 4_990)

      expect(subscription).to be_pending
      expect(subscription.amount_cents).to eq(4_990)
      expect(subscription.paid_through).to be_nil
    end

    # A referência viaja para fora do portal e volta numa requisição pública:
    # sequência adivinhável deixaria alguém tentar a sorte com o vizinho.
    it "sorteia uma referência por cobrança" do
      user = create(:user)

      references = Array.new(3) { described_class.open_for(user, amount_cents: 4_990).gateway_reference }

      expect(references.uniq.size).to eq(3)
      expect(references).to all(match(/\APREMIUM-[0-9a-f]{24}\z/))
    end
  end

  describe "#apply_gateway_status" do
    let(:subscription) { create(:subscription) }

    it "confirma o pagamento" do
      expect(subscription.apply_gateway_status("PAID")).to be(true)

      expect(subscription).to be_paid
    end

    it "concede um mês a partir de hoje" do
      freeze_time do
        subscription.apply_gateway_status("PAID")

        expect(subscription.paid_at).to eq(Time.current)
        expect(subscription.paid_through).to eq(Date.current + described_class::PERIOD)
      end
    end

    # Webhook é reenviado, e um segundo POST não pode conceder um segundo mês.
    it "é idempotente: notificação repetida não estende o prazo" do
      subscription.apply_gateway_status("PAID")
      first = subscription.paid_through

      travel 5.days do
        expect(subscription.apply_gateway_status("PAID")).to be(true)
        expect(subscription.reload.paid_through).to eq(first)
      end
    end

    it "registra recusa sem conceder prazo" do
      expect(subscription.apply_gateway_status("DECLINED")).to be(true)

      expect(subscription).to be_declined
      expect(subscription.paid_through).to be_nil
    end

    it "registra cancelamento" do
      subscription.apply_gateway_status("CANCELED")

      expect(subscription).to be_canceled
    end

    # AUTHORIZED, WAITING e IN_ANALYSIS não são desfecho. Sobrescrever com
    # "pending" apagaria um pagamento já confirmado se as notificações
    # chegassem fora de ordem.
    it "ignora situação que não é desfecho" do
      expect(subscription.apply_gateway_status("IN_ANALYSIS")).to be(false)
      expect(subscription.reload).to be_pending
    end

    it "ignora situação vazia" do
      expect(subscription.apply_gateway_status(nil)).to be(false)
    end

    it "aceita a situação em qualquer caixa" do
      expect(subscription.apply_gateway_status("paid")).to be(true)
      expect(subscription).to be_paid
    end
  end

  # Quem renova antes de vencer não perde os dias que faltavam: o mês novo parte
  # do fim do prazo antigo, não de hoje.
  describe "renovação antes do vencimento" do
    it "soma um mês ao prazo que ainda valia" do
      user = create(:user)
      first = create(:subscription, user: user)
      first.apply_gateway_status("PAID")

      travel 10.days do
        second = create(:subscription, user: user)
        second.apply_gateway_status("PAID")

        expect(second.paid_through).to eq(first.paid_through + described_class::PERIOD)
      end
    end

    # Quem deixou vencer começa de hoje, e não do prazo antigo: senão pagaria
    # por um mês que já passou.
    it "parte de hoje quando o prazo anterior já venceu" do
      user = create(:user)
      create(:subscription, :expired, user: user)

      subscription = create(:subscription, user: user)
      subscription.apply_gateway_status("PAID")

      expect(subscription.paid_through).to eq(Date.current + described_class::PERIOD)
    end
  end

  describe ".current" do
    it "traz só cobrança paga e dentro do prazo" do
      paid = create(:subscription, :paid)
      create(:subscription, :expired)
      create(:subscription)

      expect(described_class.current).to eq([ paid ])
    end

    # O último dia ainda é dia pago.
    it "inclui a cobrança que vence hoje" do
      subscription = create(:subscription, :paid, paid_through: Date.current)

      expect(described_class.current).to include(subscription)
    end
  end

  describe "banco" do
    it "recusa valor zerado, com ou sem validação" do
      subscription = build(:subscription, amount_cents: 0)

      expect(subscription).not_to be_valid
      expect { subscription.save!(validate: false) }.to raise_error(ActiveRecord::StatementInvalid)
    end

    it "recusa situação fora da lista" do
      subscription = create(:subscription)

      expect { subscription.update_column(:status, "quitado") }
        .to raise_error(ActiveRecord::StatementInvalid)
    end

    it "recusa referência repetida" do
      reference = create(:subscription).gateway_reference

      expect { create(:subscription, gateway_reference: reference) }
        .to raise_error(ActiveRecord::RecordInvalid)
    end
  end

  it "devolve o valor em reais" do
    expect(create(:subscription, amount_cents: 4_990).amount).to eq(BigDecimal("49.90"))
  end
end
