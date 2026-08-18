require "rails_helper"

RSpec.describe OauthIdentity, type: :model do
  subject { build(:oauth_identity) }

  it { is_expected.to belong_to(:user) }
  it { is_expected.to be_valid }

  it "recusa provedor fora da lista" do
    expect(build(:oauth_identity, provider: "orkut")).not_to be_valid
  end

  # Mesma dobradinha de users.status: a lista vale no modelo e no banco.
  it "barra provedor fora da lista no próprio banco" do
    identity = create(:oauth_identity)

    expect { described_class.connection.execute("UPDATE oauth_identities SET provider = 'orkut' WHERE id = #{identity.id}") }
      .to raise_error(ActiveRecord::StatementInvalid, /oauth_identities_provider_valid/)
  end

  # Sem isto, duas contas do portal apontariam para o mesmo Google e a segunda
  # sequestraria o login da primeira.
  it "não deixa duas contas do portal apontarem para a mesma conta do provedor" do
    create(:oauth_identity, provider: "google", uid: "1078")

    expect(build(:oauth_identity, provider: "google", uid: "1078")).not_to be_valid
  end

  it "permite o mesmo uid em provedores diferentes" do
    create(:oauth_identity, provider: "google", uid: "1078")

    expect(build(:oauth_identity, :facebook, uid: "1078")).to be_valid
  end

  it "some junto com o anunciante" do
    user = create(:user, :with_google)

    expect { user.destroy }.to change(described_class, :count).by(-1)
  end
end
