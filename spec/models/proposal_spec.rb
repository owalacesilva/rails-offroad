require "rails_helper"

RSpec.describe Proposal, type: :model do
  subject { build(:proposal) }

  it { is_expected.to belong_to(:ad) }
  # Proposta anônima continua valendo: user_id é opcional.
  it { is_expected.to belong_to(:user).optional }
  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_presence_of(:email) }

  it "recusa e-mail malformado" do
    expect(build(:proposal, email: "nao-e-email")).not_to be_valid
  end

  describe "#offered_value" do
    it "guarda o valor em reais, sem conversão para centavos" do
      expect(build(:proposal, offered_value: "350000").offered_value).to eq(350_000)
    end

    it "aceita vírgula como separador decimal" do
      expect(build(:proposal, offered_value: "1500,50").offered_value).to eq(1_500.50)
    end

    it "preserva as duas casas decimais no banco" do
      proposal = create(:proposal, offered_value: "1500,50")

      expect(proposal.reload.offered_value).to eq(1_500.50)
    end

    it "invalida a proposta quando o valor não é numérico" do
      expect(build(:proposal, offered_value: "combino depois")).not_to be_valid
    end

    it "devolve o valor cru digitado para o campo não esvaziar no erro" do
      proposal = build(:proposal, offered_value: "combino depois")
      proposal.valid?

      expect(proposal.offered_value_before_type_cast).to eq("combino depois")
    end

    it "recusa valor zero" do
      expect(build(:proposal, offered_value: "0")).not_to be_valid
    end
  end

  it "barra valor não positivo no próprio banco" do
    proposal = build(:proposal, offered_value: 0)

    expect { proposal.save!(validate: false) }
      .to raise_error(ActiveRecord::StatementInvalid, /proposals_offered_value_positive/)
  end
end
