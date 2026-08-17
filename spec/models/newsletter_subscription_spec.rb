require "rails_helper"

RSpec.describe NewsletterSubscription, type: :model do
  subject { build(:newsletter_subscription) }

  it { is_expected.to validate_presence_of(:email) }
  it { is_expected.to validate_uniqueness_of(:email).case_insensitive }

  it "recusa e-mail malformado" do
    expect(build(:newsletter_subscription, email: "nao-e-email")).not_to be_valid
  end

  it "guarda o e-mail em minúsculas e sem espaços" do
    subscription = create(:newsletter_subscription, email: "  Ana@Exemplo.com.BR ")

    expect(subscription.email).to eq("ana@exemplo.com.br")
  end

  describe ".subscribe" do
    it "cria a inscrição e registra a origem" do
      subscription = described_class.subscribe("nova@exemplo.com.br", source: "home")

      expect(subscription).to be_persisted
      expect(subscription.source).to eq("home")
    end

    # Reinscrever não é erro do visitante: ele segue inscrito, que é o que pediu.
    it "devolve a inscrição existente em vez de duplicar" do
      existing = create(:newsletter_subscription, email: "ana@exemplo.com.br")

      expect { described_class.subscribe("ANA@exemplo.com.br") }.not_to change(described_class, :count)
      expect(described_class.subscribe("ana@exemplo.com.br")).to eq(existing)
    end

    it "devolve um registro inválido quando o e-mail não presta" do
      subscription = described_class.subscribe("nao-e-email")

      expect(subscription).not_to be_persisted
    end
  end
end
