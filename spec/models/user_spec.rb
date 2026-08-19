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

  # Coluna à parte de status de propósito: as duas coisas são independentes — a
  # moderação bloqueia quem já confirmou, e quem confirmou pode ser bloqueado.
  describe "confirmação de e-mail" do
    it "nasce sem confirmação" do
      expect(create(:user, :unconfirmed)).not_to be_confirmed
    end

    it "confirm_email marca a data" do
      user = create(:user, :unconfirmed)

      expect { user.confirm_email }.to change(user, :confirmed?).from(false).to(true)
    end

    # Cliente de e-mail que pré-carrega links abre o mesmo link duas vezes
    # sozinho: a segunda não pode virar erro.
    it "confirm_email não muda a data de quem já confirmou" do
      user = create(:user, confirmed_at: 3.days.ago)

      expect { user.confirm_email }.not_to change { user.reload.confirmed_at }
    end

    it "o escopo confirmed deixa de fora quem não confirmou" do
      confirmed = create(:user)
      create(:user, :unconfirmed)

      expect(described_class.confirmed).to eq([ confirmed ])
    end

    describe "token do link" do
      let(:user) { create(:user, :unconfirmed) }

      it "encontra o anunciante" do
        token = user.generate_token_for(:email_confirmation)

        expect(described_class.find_by_token_for(:email_confirmation, token)).to eq(user)
      end

      it "não encontra nada com token adulterado" do
        expect(described_class.find_by_token_for(:email_confirmation, "nao-e-token")).to be_nil
      end

      # O e-mail vai dentro do token: trocar de endereço derruba o link que
      # ainda estivesse na caixa de entrada do endereço antigo.
      it "deixa de valer quando o e-mail muda" do
        token = user.generate_token_for(:email_confirmation)
        user.update!(email: "outro@exemplo.com.br")

        expect(described_class.find_by_token_for(:email_confirmation, token)).to be_nil
      end

      it "deixa de valer depois do prazo" do
        token = user.generate_token_for(:email_confirmation)

        travel(described_class::CONFIRMATION_WINDOW + 1.hour) do
          expect(described_class.find_by_token_for(:email_confirmation, token)).to be_nil
        end
      end
    end
  end

  # Quem entra por Google ou Facebook não digitou senha nenhuma, e a coluna é
  # NOT NULL.
  describe ".random_password" do
    it "gera senha longa e diferente a cada chamada" do
      first = described_class.random_password

      expect(first.length).to be >= 32
      expect(first).not_to eq(described_class.random_password)
    end
  end

  # O Premium é derivado das cobranças, e não de uma coluna em users: é
  # subscriptions.paid_through que o pagamento move.
  describe "plano Premium" do
    let(:user) { create(:user) }

    it "não é Premium sem cobrança paga" do
      create(:subscription, user: user)

      expect(user.premium?).to be(false)
      expect(user.premium_until).to be_nil
    end

    it "é Premium enquanto o prazo vale" do
      subscription = create(:subscription, :paid, user: user)

      expect(user.premium?).to be(true)
      expect(user.premium_until).to eq(subscription.paid_through)
    end

    it "deixa de ser Premium quando o prazo vence" do
      create(:subscription, :expired, user: user)

      expect(user.premium?).to be(false)
    end

    # Prazo vencido continua no histórico, então premium_until é o maior de
    # todos — o que importa é o mais longe, não o mais recente.
    it "considera o prazo mais longo entre as cobranças pagas" do
      create(:subscription, :expired, user: user)
      current = create(:subscription, :paid, user: user)

      expect(user.premium_until).to eq(current.paid_through)
    end

    it "não confunde o Premium de um anunciante com o de outro" do
      create(:subscription, :paid, user: create(:user))

      expect(user.premium?).to be(false)
    end
  end
end
