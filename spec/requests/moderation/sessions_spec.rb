require "rails_helper"

RSpec.describe "Sessão de moderação", type: :request do
  let(:admin) { create(:admin, name: "Equipe OffRoad", email: "mod@exemplo.com.br") }

  describe "GET /admin/entrar" do
    it "responde com sucesso sem sessão" do
      get admin_login_path

      expect(response).to have_http_status(:ok)
    end

    it "não deixa nenhuma chave de tradução sem valor" do
      get admin_login_path

      expect(response.body).not_to include("translation missing")
    end
  end

  describe "POST /admin/entrar" do
    it "com credenciais válidas abre a fila" do
      sign_in_admin(admin)

      expect(response).to redirect_to(admin_root_path)
    end

    it "com credenciais válidas cria a sessão de moderador" do
      expect { sign_in_admin(admin) }.to change(AdminSession, :count).by(1)
    end

    it "com senha errada não cria sessão" do
      expect { sign_in_admin(admin, password: "errada") }.not_to change(AdminSession, :count)
    end

    it "com senha errada devolve 422" do
      sign_in_admin(admin, password: "errada")

      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "DELETE /admin/sair" do
    it "encerra a sessão de moderador" do
      sign_in_admin(admin)

      expect { delete admin_logout_path }.to change(AdminSession, :count).by(-1)
    end
  end

  describe "proteção da área" do
    it "manda para o login quem não é moderador" do
      get admin_ads_path

      expect(response).to redirect_to(admin_login_path)
    end

    # A sessão de anunciante não vale na moderação: são cookies e tabelas separados.
    it "não aceita sessão de anunciante como moderador" do
      sign_in(create(:user))

      get admin_ads_path

      expect(response).to redirect_to(admin_login_path)
    end
  end
end
