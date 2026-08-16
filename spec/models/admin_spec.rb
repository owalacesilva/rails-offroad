require "rails_helper"

RSpec.describe Admin, type: :model do
  subject { build(:admin) }

  it { is_expected.to have_many(:admin_sessions).dependent(:destroy) }
  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_presence_of(:email) }

  it "normaliza o e-mail para minúsculas sem espaços" do
    admin = create(:admin, email: "  Moderacao@Exemplo.COM  ")

    expect(admin.email).to eq("moderacao@exemplo.com")
  end

  it "recusa e-mail repetido" do
    create(:admin, email: "mod@exemplo.com")

    expect(build(:admin, email: "mod@exemplo.com")).not_to be_valid
  end

  it "recusa e-mail malformado" do
    expect(build(:admin, email: "nao-e-email")).not_to be_valid
  end

  # A coluna é password_hash, não password_digest: o alias liga has_secure_password.
  it "autentica pela coluna password_hash" do
    admin = create(:admin, password: "trilha123")

    expect(admin.authenticate("trilha123")).to eq(admin)
    expect(admin.authenticate("errada")).to be(false)
  end

  it "guarda o hash, nunca a senha em claro" do
    admin = create(:admin, password: "trilha123")

    expect(admin.password_hash).to be_present
    expect(admin.password_hash).not_to include("trilha123")
  end

  it "solta o anúncio avaliado ao ser removido, sem apagar o anúncio" do
    admin = create(:admin)
    ad = create(:ad, admin: admin)

    admin.destroy

    expect(ad.reload.admin_id).to be_nil
  end
end
