require "rails_helper"

RSpec.describe "Sessões", type: :request do
  let!(:user) { create(:user, name: "Garagem Trilha Livre", email: "contato@trilha.com.br") }

  describe "GET /entrar" do
    it "responde com sucesso" do
      get login_path

      expect(response).to have_http_status(:ok)
    end

    it "não deixa nenhuma chave de tradução sem valor" do
      get login_path

      expect(response.body).not_to include("translation missing")
    end
  end

  describe "POST /entrar com credenciais corretas" do
    it "cria a sessão no banco" do
      expect { sign_in(user) }.to change(Session, :count).by(1)
    end

    it "prende a sessão ao anunciante" do
      sign_in(user)

      expect(Session.last.user).to eq(user)
    end

    it "guarda user agent e IP da sessão" do
      sign_in(user)

      expect(Session.last.ip_address).to be_present
    end

    it "redireciona para a home" do
      sign_in(user)

      expect(response).to redirect_to(root_url)
    end

    it "aceita e-mail em outra caixa" do
      post login_path, params: { email: "CONTATO@TRILHA.COM.BR", password: "trilha123" }

      expect(response).to redirect_to(root_url)
    end

    it "passa a mostrar o nome no header" do
      sign_in(user)
      get root_path

      expect(response.body).to include(user.name)
    end
  end

  describe "POST /entrar com credenciais erradas" do
    it "não cria sessão" do
      expect { sign_in(user, password: "errada") }.not_to change(Session, :count)
    end

    it "responde 422" do
      sign_in(user, password: "errada")

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "avisa sem revelar se o e-mail existe" do
      sign_in(user, password: "errada")

      expect(response.body).to include(I18n.t("sessions.create.failure"))
    end

    it "dá a mesma resposta para e-mail inexistente" do
      post login_path, params: { email: "ninguem@exemplo.com.br", password: "trilha123" }

      expect(response.body).to include(I18n.t("sessions.create.failure"))
    end
  end

  describe "quem já está autenticado" do
    before { sign_in(user) }

    it "é mandado embora do formulário de login" do
      get login_path

      expect(response).to redirect_to(root_path)
    end

    it "é mandado embora do cadastro" do
      get signup_path

      expect(response).to redirect_to(root_path)
    end
  end

  describe "DELETE /sair" do
    it "destrói a sessão do banco" do
      sign_in(user)

      expect { delete logout_path }.to change(Session, :count).by(-1)
    end

    it "volta a mostrar o link de entrar" do
      sign_in(user)
      delete logout_path
      get root_path

      expect(response.body).to include(I18n.t("layout.header.sign_in"))
    end

    # Única action hoje que não declara allow_unauthenticated_access: prova que
    # o padrão do Authentication é negar.
    it "manda para o login quem não tem sessão" do
      delete logout_path

      expect(response).to redirect_to(login_path)
    end

    it "explica por que redirecionou" do
      delete logout_path
      follow_redirect!

      expect(response.body).to include(I18n.t("sessions.required"))
    end
  end
end
