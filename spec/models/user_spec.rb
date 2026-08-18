require "rails_helper"

RSpec.describe User, type: :model do
  subject { build(:user) }

  it { is_expected.to have_secure_password }
  it { is_expected.to have_many(:ads).dependent(:restrict_with_error) }
  it { is_expected.to have_many(:sessions).dependent(:destroy) }
  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_presence_of(:city) }
  it { is_expected.to validate_presence_of(:member_since) }
  it { is_expected.to validate_uniqueness_of(:email).case_insensitive }
  it { is_expected.to validate_inclusion_of(:state).in_array(described_class::BRAZILIAN_STATES) }

  describe "normalização de e-mail" do
    it "guarda em minúsculas e sem espaços" do
      user = create(:user, email: "  CONTATO@Trilha.com.BR ")

      expect(user.email).to eq("contato@trilha.com.br")
    end

    it "encontra o registro por e-mail não normalizado" do
      user = create(:user, email: "contato@trilha.com.br")

      expect(described_class.find_by(email: "CONTATO@TRILHA.COM.BR")).to eq(user)
    end
  end

  describe ".normalize_phone" do
    it "acrescenta o código do país a número com DDD" do
      expect(described_class.normalize_phone("(41) 98877-0011")).to eq("5541988770011")
    end

    it "aceita número fixo de dez dígitos" do
      expect(described_class.normalize_phone("4133334444")).to eq("554133334444")
    end

    # Prefixo seria ambíguo: 55 também é o DDD de Santa Maria (RS).
    it "não duplica o país em número que já tem treze dígitos" do
      expect(described_class.normalize_phone("5541988770011")).to eq("5541988770011")
    end

    it "trata DDD 55 como DDD, não como código do país" do
      expect(described_class.normalize_phone("55999887766")).to eq("5555999887766")
    end
  end

  describe "telefone" do
    it "aceita entrada formatada, porque a normalização roda antes da validação" do
      expect(build(:user, phone: "(41) 98877-0011")).to be_valid
    end

    it "recusa número curto demais" do
      expect(build(:user, phone: "1234")).not_to be_valid
    end
  end

  describe "autenticação" do
    let!(:user) { create(:user, email: "contato@trilha.com.br", password: "trilha123") }

    it "autentica com a senha correta" do
      expect(described_class.authenticate_by(email: "contato@trilha.com.br", password: "trilha123")).to eq(user)
    end

    it "normaliza o e-mail na autenticação" do
      expect(described_class.authenticate_by(email: "CONTATO@TRILHA.COM.BR", password: "trilha123")).to eq(user)
    end

    it "recusa a senha errada" do
      expect(described_class.authenticate_by(email: "contato@trilha.com.br", password: "errada")).to be_nil
    end

    it "não guarda a senha em texto puro" do
      expect(user.password_digest).not_to include("trilha123")
    end
  end

  describe "#location" do
    it "junta cidade e UF" do
      expect(build(:user, city: "Cuiabá", state: "MT").location).to eq("Cuiabá, MT")
    end
  end

  # active / inactive / blocked. Inativo é quem saiu; bloqueado é quem a
  # moderação tirou do ar. Os dois somem do portal.
  describe "situação" do
    it "nasce ativo" do
      expect(described_class.new.status).to eq("active")
    end

    it "aceita as três situações" do
      expect(described_class.statuses.keys).to contain_exactly("active", "inactive", "blocked")
    end

    it "barra situação fora da lista no próprio banco" do
      user = create(:user)

      expect { described_class.connection.execute("UPDATE users SET status = 'sumido' WHERE id = #{user.id}") }
        .to raise_error(ActiveRecord::StatementInvalid, /users_status_valid/)
    end

    it "o escopo active traz só quem está ativo" do
      active = create(:user)
      create(:user, status: :blocked)
      create(:user, status: :inactive)

      expect(described_class.active).to eq([ active ])
    end
  end
end
