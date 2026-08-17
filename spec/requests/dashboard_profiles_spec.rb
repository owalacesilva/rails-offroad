require "rails_helper"

RSpec.describe "Meu Perfil", type: :request do
  let(:user) { create(:user, name: "Garagem Trilha Livre", city: "Curitiba", state: "PR") }
  let(:valid_attributes) do
    { name: "Garagem Trilha Livre", email: user.email, phone: "41988770011", city: "Curitiba", state: "PR" }
  end

  before { sign_in(user) }

  describe "GET /anunciante/perfil" do
    it "responde com sucesso" do
      get edit_profile_path

      expect(response).to have_http_status(:ok)
    end

    it "não deixa nenhuma chave de tradução sem valor" do
      get edit_profile_path

      expect(response.body).not_to include("translation missing")
    end
  end

  describe "PATCH /anunciante/perfil" do
    it "salva os dados" do
      patch profile_path, params: { user: valid_attributes.merge(city: "Joinville", state: "SC") }

      expect(user.reload).to have_attributes(city: "Joinville", state: "SC")
    end

    it "volta para o dashboard" do
      patch profile_path, params: { user: valid_attributes }

      expect(response).to redirect_to(account_path)
    end

    # A controller vive em Dashboard::, então t(".success") apontaria para a
    # chave errada e o aviso viraria "translation missing" na tela.
    it "confirma na tela com a mensagem traduzida" do
      patch profile_path, params: { user: valid_attributes }
      follow_redirect!

      expect(response.body).to include(I18n.t("profiles.update.success"))
      expect(response.body).not_to include("translation missing")
    end

    it "mantém a senha atual quando os campos vêm em branco" do
      patch profile_path, params: { user: valid_attributes.merge(password: "", password_confirmation: "") }

      expect(user.reload.authenticate("trilha123")).to eq(user)
    end

    it "troca a senha quando preenchida" do
      patch profile_path, params: { user: valid_attributes.merge(password: "novasenha123", password_confirmation: "novasenha123") }

      expect(user.reload.authenticate("novasenha123")).to eq(user)
    end

    it "devolve 422 com dados inválidos" do
      patch profile_path, params: { user: valid_attributes.merge(email: "nao-e-email") }

      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  it "exige sessão" do
    delete logout_path

    get edit_profile_path

    expect(response).to redirect_to(login_path)
  end
end
