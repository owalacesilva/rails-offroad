require "rails_helper"

RSpec.describe "Blog público", type: :request do
  describe "GET /blog" do
    it "responde sem exigir login" do
      get posts_path

      expect(response).to have_http_status(:ok)
    end

    it "não deixa nenhuma chave de tradução sem valor" do
      create(:post)

      get posts_path

      expect(response.body).not_to include("translation missing")
    end

    it "lista o que está publicado" do
      post = create(:post, title: "Como escolher pneu")

      get posts_path

      expect(response.body).to include(post.title)
    end

    # Rascunho e agendado são invisíveis para o público: é o que separa as duas
    # audiências, sem coluna de status.
    it "não lista rascunho" do
      create(:post, :draft, title: "Rascunho secreto")

      get posts_path

      expect(response.body).not_to include("Rascunho secreto")
    end

    it "não lista post agendado" do
      create(:post, :scheduled, title: "Sai semana que vem")

      get posts_path

      expect(response.body).not_to include("Sai semana que vem")
    end

    it "ordena do mais recente para o mais antigo" do
      create(:post, title: "Post antigo", published_at: 10.days.ago)
      create(:post, title: "Post novo", published_at: 1.hour.ago)

      get posts_path

      expect(response.body.index("Post novo")).to be < response.body.index("Post antigo")
    end

    it "pagina quando passa do limite da página" do
      create_list(:post, PostsController::PER_PAGE + 1)

      get posts_path

      expect(response.body).to include(I18n.t("shared.pagination.next"))
    end

    it "explica o blog vazio" do
      get posts_path

      expect(response.body).to include(I18n.t("posts.index.empty.title"))
    end
  end

  describe "GET /blog/:slug" do
    let(:post_record) { create(:post, title: "Como escolher pneu", body: "<h3>Composto</h3><p>Texto.</p>") }

    it "abre pela slug, não pelo id" do
      get post_path(post_record)

      expect(response).to have_http_status(:ok)
      expect(post_path(post_record)).to end_with(post_record.slug)
    end

    it "mostra o corpo já formatado" do
      get post_path(post_record)

      expect(response.body).to include("<h3>Composto</h3>")
    end

    it "credita o autor" do
      get post_path(post_record)

      expect(response.body).to include(I18n.t("posts.by", name: post_record.admin.name))
    end

    it "devolve 404 para rascunho" do
      draft = create(:post, :draft)

      get post_path(draft)

      expect(response).to have_http_status(:not_found)
    end

    it "devolve 404 para post agendado" do
      scheduled = create(:post, :scheduled)

      get post_path(scheduled)

      expect(response).to have_http_status(:not_found)
    end

    it "sugere outros posts publicados" do
      post_record
      other = create(:post, title: "Outro texto")

      get post_path(post_record)

      expect(response.body).to include(other.title)
    end

    # O título do post aparece no <title> e no <h1>: a asserção precisa olhar
    # só o bloco de sugestões.
    it "não sugere o próprio post" do
      create(:post, title: "Outro texto")

      get post_path(post_record)

      related = response.body[/#{I18n.t('posts.show.related')}(.*)/m, 1]

      expect(related).to include("Outro texto")
      expect(related).not_to include(post_record.title)
    end
  end

  describe "home" do
    it "mostra os últimos posts" do
      post_record = create(:post, title: "Último texto")

      get root_path

      expect(response.body).to include(post_record.title, I18n.t("home.posts.title"))
    end

    it "leva para o blog inteiro" do
      get root_path

      expect(response.body).to include(posts_path)
    end

    it "mostra no máximo o limite da home" do
      create_list(:post, HomeController::POSTS_LIMIT + 2)

      get root_path

      section = response.body[/#{I18n.t('home.posts.title')}(.*?)#{I18n.t('home.newsletter.title')}/m, 1]

      expect(section.scan("<article").size).to eq(HomeController::POSTS_LIMIT)
    end

    it "não mostra rascunho na home" do
      create(:post, :draft, title: "Rascunho da home")

      get root_path

      expect(response.body).not_to include("Rascunho da home")
    end
  end
end
