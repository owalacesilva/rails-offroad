require "rails_helper"

RSpec.describe "Gestão de anunciantes", type: :request do
  let(:admin) { create(:admin) }

  before { sign_in_admin(admin) }

  describe "GET /admin/anunciantes" do
    it "responde com sucesso" do
      get admin_users_path

      expect(response).to have_http_status(:ok)
    end

    it "não deixa nenhuma chave de tradução sem valor" do
      create(:user)

      get admin_users_path

      expect(response.body).not_to include("translation missing")
    end

    it "lista todos por padrão" do
      active = create(:user, name: "Garagem Ativa")
      blocked = create(:user, name: "Garagem Bloqueada", status: :blocked)

      get admin_users_path

      expect(response.body).to include(active.name, blocked.name)
    end

    it "filtra pela situação pedida" do
      create(:user, name: "Garagem Ativa")
      create(:user, name: "Garagem Bloqueada", status: :blocked)

      get admin_users_path(status: "blocked")

      expect(response.body).to include("Garagem Bloqueada")
      expect(response.body).not_to include("Garagem Ativa")
    end

    it "busca por nome" do
      create(:user, name: "Garagem Trilha Livre")
      create(:user, name: "Outra Coisa")

      get admin_users_path(q: "trilha")

      expect(response.body).to include("Garagem Trilha Livre")
      expect(response.body).not_to include("Outra Coisa")
    end

    it "busca por e-mail" do
      wanted = create(:user, email: "achado@exemplo.com.br", name: "Quem Procuro")
      create(:user, name: "Outra Coisa")

      get admin_users_path(q: "achado@")

      expect(response.body).to include(wanted.name)
      expect(response.body).not_to include("Outra Coisa")
    end

    # % e _ digitados na busca não podem virar curinga.
    it "escapa curinga digitado na busca" do
      create(:user, name: "Garagem Trilha")

      get admin_users_path(q: "%")

      expect(response.body).not_to include("Garagem Trilha")
    end

    it "explica a lista vazia" do
      get admin_users_path(q: "nao-existe")

      expect(response.body).to include(I18n.t("admin.users.index.empty.title"))
    end
  end

  describe "PATCH /admin/anunciantes/:id/situacao" do
    let(:user) { create(:user) }

    it "bloqueia o anunciante" do
      patch status_admin_user_path(user, to: "blocked")

      expect(user.reload).to be_blocked
    end

    # Bloquear tem de tirar os anúncios do portal sem mexer em cada um.
    it "tira os anúncios dele do portal" do
      create(:ad, user: user)

      patch status_admin_user_path(user, to: "blocked")

      expect(Ad.published.where(user: user)).to be_empty
    end

    it "reativa e devolve os anúncios ao portal" do
      ad = create(:ad, user: user)
      user.blocked!

      patch status_admin_user_path(user, to: "active")

      expect(Ad.published).to include(ad)
    end

    it "desativa o anunciante" do
      patch status_admin_user_path(user, to: "inactive")

      expect(user.reload).to be_inactive
    end

    it "avisa qual foi a mudança" do
      patch status_admin_user_path(user, to: "blocked")

      expect(flash[:notice]).to include(user.name)
    end

    # Situação inventada não pode virar 500 nem gravar lixo na coluna.
    it "cai em ativo quando a situação pedida não existe" do
      user.blocked!

      patch status_admin_user_path(user, to: "inventada")

      expect(user.reload).to be_active
    end
  end

  describe "acesso" do
    it "exige sessão de moderador" do
      delete admin_logout_path

      get admin_users_path

      expect(response).to redirect_to(admin_login_path)
    end

    it "não muda situação sem sessão de moderador" do
      user = create(:user)
      delete admin_logout_path

      patch status_admin_user_path(user, to: "blocked")

      expect(user.reload).to be_active
    end
  end
end
