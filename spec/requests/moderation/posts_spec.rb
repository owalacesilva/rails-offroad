require "rails_helper"

RSpec.describe "Gestão do blog", type: :request do
  let(:admin) { create(:admin) }

  let(:valid_attributes) do
    { title: "Como escolher pneu de trilha", excerpt: "Chamada curta.",
      body: "<p>Corpo do texto.</p>", published_at: 1.hour.ago }
  end

  before { sign_in_admin(admin) }

  describe "GET /admin/blog" do
    it "responde com sucesso" do
      get admin_posts_path

      expect(response).to have_http_status(:ok)
    end

    it "não deixa nenhuma chave de tradução sem valor" do
      create(:post, admin: admin)

      get admin_posts_path

      expect(response.body).not_to include("translation missing")
    end

    # A aba padrão é a que o público vê.
    it "abre nos publicados" do
      create(:post, admin: admin, title: "Está no ar")
      create(:post, :draft, admin: admin, title: "Ainda escrevendo")

      get admin_posts_path

      expect(response.body).to include("Está no ar")
      expect(response.body).not_to include("Ainda escrevendo")
    end

    it "mostra os rascunhos quando pedido" do
      create(:post, admin: admin, title: "Está no ar")
      create(:post, :draft, admin: admin, title: "Ainda escrevendo")

      get admin_posts_path(scope: "drafts")

      expect(response.body).to include("Ainda escrevendo")
      expect(response.body).not_to include("Está no ar")
    end

    it "mostra os agendados quando pedido" do
      create(:post, :scheduled, admin: admin, title: "Sai semana que vem")

      get admin_posts_path(scope: "scheduled")

      expect(response.body).to include("Sai semana que vem")
    end

    it "cai nos publicados quando a aba pedida não existe" do
      create(:post, admin: admin, title: "Está no ar")

      get admin_posts_path(scope: "inventada")

      expect(response.body).to include("Está no ar")
    end

    it "explica a lista vazia" do
      get admin_posts_path

      expect(response.body).to include(I18n.t("admin.posts.index.empty.published.title"))
    end
  end

  describe "POST /admin/blog" do
    it "cria o post" do
      expect { post admin_posts_path, params: { post: valid_attributes } }.to change(Post, :count).by(1)
    end

    # O autor sai da sessão de moderador; o formulário não oferece o campo.
    it "credita quem está logado como autor" do
      post admin_posts_path, params: { post: valid_attributes }

      expect(Post.last.admin).to eq(admin)
    end

    it "não aceita autor vindo do formulário" do
      other = create(:admin)

      post admin_posts_path, params: { post: valid_attributes.merge(admin_id: other.id) }

      expect(Post.last.admin).to eq(admin)
    end

    it "limpa o corpo na entrada" do
      post admin_posts_path, params: { post: valid_attributes.merge(body: "<p>ok</p><script>alert(1)</script>") }

      expect(Post.last.body).not_to include("<script")
    end

    it "nasce rascunho quando não há data de publicação" do
      post admin_posts_path, params: { post: valid_attributes.merge(published_at: "") }

      expect(Post.last).not_to be_published
    end

    it "redireciona para a lista com aviso" do
      post admin_posts_path, params: { post: valid_attributes }

      expect(response).to redirect_to(admin_posts_path)
      expect(flash[:notice]).to include(valid_attributes[:title])
    end

    it "devolve o formulário com 422 quando falta título" do
      post admin_posts_path, params: { post: valid_attributes.merge(title: "") }

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "recusa capa que não é http" do
      attributes = valid_attributes.merge(cover_url: "javascript:alert(1)")

      expect { post admin_posts_path, params: { post: attributes } }.not_to change(Post, :count)
    end
  end

  describe "PATCH /admin/blog/:slug" do
    let(:record) { create(:post, :draft, admin: admin, title: "Nome antigo") }

    it "atualiza o post" do
      patch admin_post_path(record), params: { post: { title: "Nome novo" } }

      expect(record.reload.title).to eq("Nome novo")
    end

    # É assim que um rascunho vai ao ar.
    it "publica ao ganhar data" do
      patch admin_post_path(record), params: { post: { published_at: 1.minute.ago } }

      expect(record.reload).to be_published
    end

    it "devolve o formulário com 422 quando algo falha" do
      patch admin_post_path(record), params: { post: { title: "" } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(record.reload.title).to eq("Nome antigo")
    end

    it "volta para a aba de onde veio" do
      patch admin_post_path(record, scope: "drafts"), params: { post: { title: "Nome novo" } }

      expect(response).to redirect_to(admin_posts_path(scope: "drafts"))
    end
  end

  describe "DELETE /admin/blog/:slug" do
    it "apaga o post" do
      record = create(:post, admin: admin)

      expect { delete admin_post_path(record) }.to change(Post, :count).by(-1)
    end
  end

  describe "acesso" do
    it "exige sessão de moderador" do
      delete admin_logout_path

      get admin_posts_path

      expect(response).to redirect_to(admin_login_path)
    end

    it "não aceita sessão de anunciante no lugar da de moderador" do
      delete admin_logout_path
      sign_in(create(:user))

      get admin_posts_path

      expect(response).to redirect_to(admin_login_path)
    end

    it "não cria post sem sessão de moderador" do
      delete admin_logout_path

      expect { post admin_posts_path, params: { post: valid_attributes } }.not_to change(Post, :count)
    end
  end
end
