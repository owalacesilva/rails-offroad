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

    it "lista os anunciantes" do
      user = create(:user, name: "Garagem Trilha Livre")

      get admin_users_path

      expect(response.body).to include(user.name)
    end
  end

  describe "a tabela" do
    before do
      create(:user, name: "Garagem Trilha Livre", phone: "5541988770011")
      get admin_users_path
    end

    it "monta uma tabela de verdade" do
      expect(response.body).to include("<table", "<thead", "<tbody")
    end

    it "usa cabeçalhos em caixa alta" do
      expect(response.body).to match(/<th[^>]*class="[^"]*uppercase/)
    end

    it "risca as linhas em zebra" do
      expect(response.body).to include("nth-child(even)")
    end

    it "traz uma caixa de seleção por linha e a do cabeçalho" do
      expect(response.body).to include(%(name="user_ids[]"), 'id="select-all"')
    end

    it "traz o avatar com a inicial" do
      expect(response.body).to match(/rounded-full[^"]*">\s*G/)
    end

    it "mostra o telefone com máscara, não os dígitos crus" do
      expect(response.body).to include("(41) 9 8877-0011")
      expect(response.body).not_to include("5541988770011")
    end

    it "mostra a contagem de anúncios do anunciante" do
      expect(response.body).to include(t_column("ads_column"))
    end

    # <table> dentro de <form> não é HTML válido: as caixas apontam para o
    # formulário irmão pelo atributo form.
    it "liga as caixas ao formulário em lote sem aninhar table em form" do
      expect(response.body).to include('form="bulk-status-form"')
      expect(response.body).not_to match(/<form[^>]*>\s*<table/)
    end

    def t_column(key)
      I18n.t("admin.users.index.#{key}")
    end
  end

  describe "colunas ordenáveis" do
    before do
      create(:user, name: "Zulu")
      create(:user, name: "Alfa")
    end

    it "ordena pela coluna pedida" do
      get admin_users_path(sort: "name", dir: "asc")

      expect(response.body.index("Alfa")).to be < response.body.index("Zulu")
    end

    it "inverte quando a direção muda" do
      get admin_users_path(sort: "name", dir: "desc")

      expect(response.body.index("Zulu")).to be < response.body.index("Alfa")
    end

    it "anuncia a ordenação para leitor de tela" do
      get admin_users_path(sort: "name", dir: "asc")

      expect(response.body).to include('aria-sort="ascending"')
    end

    it "o cabeçalho leva para a direção invertida" do
      get admin_users_path(sort: "name", dir: "asc")

      expect(response.body).to include(ERB::Util.html_escape(admin_users_path(sort: "name", dir: "desc")))
    end
  end

  describe "o filtro" do
    before do
      create(:user, name: "Garagem Trilha Livre", email: "trilha@exemplo.com.br", phone: "5541988770011")
      create(:user, name: "Outra Coisa", email: "outra@exemplo.com.br", phone: "5511977660022", status: :blocked)
    end

    it "filtra por nome" do
      get admin_users_path(name: "trilha")

      expect(response.body).to include("Garagem Trilha Livre")
      expect(response.body).not_to include("Outra Coisa")
    end

    it "filtra por e-mail" do
      get admin_users_path(email: "outra@")

      expect(response.body).to include("Outra Coisa")
      expect(response.body).not_to include("Garagem Trilha Livre")
    end

    it "filtra por telefone" do
      get admin_users_path(phone: "(41) 9")

      expect(response.body).to include("Garagem Trilha Livre")
      expect(response.body).not_to include("Outra Coisa")
    end

    it "filtra por situação" do
      get admin_users_path(status: "blocked")

      expect(response.body).to include("Outra Coisa")
      expect(response.body).not_to include("Garagem Trilha Livre")
    end

    it "filtra por quantidade de anúncios" do
      busy = create(:user, name: "Garagem Cheia")
      create_list(:ad, 3, user: busy)

      get admin_users_path(min_ads: "3")

      expect(response.body).to include("Garagem Cheia")
      expect(response.body).not_to include("Outra Coisa")
    end

    it "conta os filtros ativos" do
      get admin_users_path(name: "trilha", status: "active")

      expect(response.body).to include(I18n.t("admin.users.filters.applied", count: 2))
    end

    # O painel renderiza aberto: sem JavaScript o filtro continua utilizável, e
    # o botão é quem recolhe.
    it "oferece o botão de recolher" do
      get admin_users_path

      expect(response.body).to include('data-action="filters#toggle"', 'data-filters-target="panel"')
    end

    it "oferece o limpar tudo apontando para a tela sem parâmetro" do
      get admin_users_path(name: "trilha")

      expect(response.body).to include(I18n.t("admin.users.filters.clear"))
    end

    it "guarda a ordenação ao aplicar o filtro" do
      get admin_users_path(sort: "ads", dir: "asc")

      expect(response.body).to include(%(name="sort" id="sort" value="ads"))
    end

    it "explica a lista vazia" do
      get admin_users_path(name: "nao-existe")

      expect(response.body).to include(I18n.t("admin.users.index.empty.title"))
    end
  end

  describe "paginação" do
    before { create_list(:user, Moderation::UsersController::PER_PAGE + 5) }

    it "corta na primeira página" do
      get admin_users_path

      expect(response.body.scan(%(name="user_ids[]")).size).to eq(Moderation::UsersController::PER_PAGE)
    end

    it "oferece a navegação" do
      get admin_users_path

      expect(response.body).to include(I18n.t("shared.pagination.next"))
    end

    it "mostra a segunda página" do
      get admin_users_path(page: 2)

      expect(response.body.scan(%(name="user_ids[]")).size).to eq(5)
    end

    # A régua tem de carregar o filtro: paginar não pode desfazer a busca.
    it "preserva o filtro nos links de página" do
      get admin_users_path(name: "Teste", page: 1)

      expect(response.body).to include("name=Teste") if response.body.include?("page=2")
    end

    # O rodapé fecha o mesmo card da tabela; a contagem, que antes ficava numa
    # linha à parte, entrou nele.
    it "põe a contagem no rodapé, junto dos botões" do
      get admin_users_path

      total = Moderation::UsersController::PER_PAGE + 5
      showing = I18n.t("shared.pagination.showing", from: 1, to: Moderation::UsersController::PER_PAGE, total: total)

      expect(response.body).to include(showing)
      expect(response.body.scan(showing).size).to eq(1)
    end
  end

  describe "PATCH situação individual" do
    let(:user) { create(:user) }

    it "bloqueia o anunciante" do
      patch status_admin_user_path(user, to: "blocked")

      expect(user.reload).to be_blocked
    end

    it "tira os anúncios dele do portal" do
      create(:ad, user: user)

      patch status_admin_user_path(user, to: "blocked")

      expect(Ad.published.where(user: user)).to be_empty
    end

    it "volta para a lista como ela estava" do
      patch status_admin_user_path(user, to: "blocked", list: { name: "trilha", page: "2" })

      expect(response).to redirect_to(admin_users_path(name: "trilha", page: "2"))
    end

    it "cai em ativo quando a situação pedida não existe" do
      user.blocked!

      patch status_admin_user_path(user, to: "inventada")

      expect(user.reload).to be_active
    end
  end

  describe "PATCH situação em lote" do
    let(:users) { create_list(:user, 3) }

    it "muda a situação de todos os marcados" do
      patch bulk_status_admin_users_path, params: { user_ids: users.map(&:id), to: "blocked" }

      expect(users.map { |user| user.reload.status }).to all(eq("blocked"))
    end

    it "não toca em quem não foi marcado" do
      untouched = create(:user)

      patch bulk_status_admin_users_path, params: { user_ids: users.map(&:id), to: "blocked" }

      expect(untouched.reload).to be_active
    end

    it "avisa quantos mudaram" do
      patch bulk_status_admin_users_path, params: { user_ids: users.map(&:id), to: "blocked" }

      expect(flash[:notice]).to include("3")
    end

    it "avisa quando nada foi marcado" do
      patch bulk_status_admin_users_path, params: { to: "blocked" }

      expect(flash[:alert]).to eq(I18n.t("admin.users.bulk.none"))
    end

    it "cai em ativo quando a situação pedida não existe" do
      users.each(&:blocked!)

      patch bulk_status_admin_users_path, params: { user_ids: users.map(&:id), to: "inventada" }

      expect(users.map { |user| user.reload.status }).to all(eq("active"))
    end
  end

  describe "acesso" do
    it "exige sessão de moderador" do
      delete admin_logout_path

      get admin_users_path

      expect(response).to redirect_to(admin_login_path)
    end

    it "não muda situação em lote sem sessão de moderador" do
      users = create_list(:user, 2)
      delete admin_logout_path

      patch bulk_status_admin_users_path, params: { user_ids: users.map(&:id), to: "blocked" }

      expect(users.map { |user| user.reload.status }).to all(eq("active"))
    end
  end
end
