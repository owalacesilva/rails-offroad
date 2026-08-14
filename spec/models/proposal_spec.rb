require "rails_helper"

RSpec.describe Proposal, type: :model do
  subject { build(:proposal) }

  it { is_expected.to belong_to(:listing) }
  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_presence_of(:email) }

  it "recusa e-mail malformado" do
    expect(build(:proposal, email: "nao-e-email")).not_to be_valid
  end

  describe "#amount" do
    it "converte reais em centavos ao atribuir" do
      expect(build(:proposal, amount: "350000").amount_cents).to eq(35_000_000)
    end

    it "aceita vírgula como separador decimal" do
      expect(build(:proposal, amount: "1500,50").amount_cents).to eq(150_050)
    end

    it "converte centavos de volta para reais ao ler" do
      expect(build(:proposal, amount_cents: 35_000_000).amount).to eq(350_000)
    end

    it "zera os centavos quando o valor não é numérico" do
      expect(build(:proposal, amount: "combino depois").amount_cents).to be_nil
    end

    it "invalida a proposta quando o valor não é numérico" do
      expect(build(:proposal, amount: "combino depois")).not_to be_valid
    end

    it "devolve o valor cru digitado para o campo não esvaziar no erro" do
      proposal = build(:proposal, amount: "combino depois")
      proposal.valid?

      expect(proposal.amount).to eq("combino depois")
    end

    it "recusa valor zero" do
      expect(build(:proposal, amount: "0")).not_to be_valid
    end
  end

  it "barra valor não positivo no próprio banco" do
    proposal = build(:proposal, amount_cents: 0)

    expect { proposal.save!(validate: false) }
      .to raise_error(ActiveRecord::StatementInvalid, /proposals_amount_cents_positive/)
  end
end
