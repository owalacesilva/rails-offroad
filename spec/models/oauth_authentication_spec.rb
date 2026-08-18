require "rails_helper"

RSpec.describe OauthAuthentication do
  subject(:authentication) { described_class.new(profile) }

  let(:profile) do
    OauthProfile.new(provider: "google", uid: "1078", email: "piloto@gmail.com", name: "Piloto")
  end

  describe "#user" do
    # O uid é o que não muda: quem trocou o endereço no Google continua sendo a
    # mesma pessoa aqui.
    it "acha pelo vínculo, mesmo com outro e-mail no portal" do
      identity = create(:oauth_identity, provider: "google", uid: "1078")

      expect(authentication.user).to eq(identity.user)
    end

    it "acha pelo e-mail quem se cadastrou com senha" do
      user = create(:user, email: "piloto@gmail.com")

      expect(authentication.user).to eq(user)
    end

    it "não acha ninguém quando a conta ainda não existe" do
      expect(authentication.user).to be_nil
    end

    it "ignora vínculo de outro provedor com o mesmo uid" do
      create(:oauth_identity, :facebook, uid: "1078")

      expect(authentication.user).to be_nil
    end
  end

  describe "#connect" do
    it "cria o vínculo de quem foi encontrado pelo e-mail" do
      user = create(:user, email: "piloto@gmail.com")

      expect { authentication.connect(user) }.to change(user.oauth_identities, :count).by(1)
      expect(user.oauth_identities.last.uid).to eq("1078")
    end

    # O provedor já verificou o endereço: pedir confirmação por e-mail a quem
    # chegou por ele seria pedir duas vezes a mesma prova.
    it "confirma o e-mail de quem chegou pelo provedor" do
      user = create(:user, :unconfirmed, email: "piloto@gmail.com")

      authentication.connect(user)

      expect(user.reload).to be_confirmed
    end

    it "não duplica vínculo que já existe" do
      identity = create(:oauth_identity, provider: "google", uid: "1078")

      expect { authentication.connect(identity.user) }.not_to change(OauthIdentity, :count)
      expect(authentication.connect(identity.user)).to be(true)
    end

    # Duas contas do Google no mesmo anunciante não é caso para resolver
    # adivinhando qual vale.
    it "recusa quando o anunciante já ligou outra conta do mesmo provedor" do
      user = create(:user, email: "piloto@gmail.com")
      create(:oauth_identity, user: user, provider: "google", uid: "outro-uid")

      expect(authentication.connect(user)).to be(false)
      expect(user.oauth_identities.count).to eq(1)
    end
  end
end
