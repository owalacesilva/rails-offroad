require "rails_helper"

RSpec.describe "Fila de moderação", type: :request do
  let(:admin) { create(:admin) }
  let(:vehicles) { create(:category, :vehicles) }

  before { sign_in_admin(admin) }

  describe "GET /admin/anuncios" do
    it "responde com sucesso" do
      get admin_ads_path

      expect(response).to have_http_status(:ok)
    end

    it "não deixa nenhuma chave de tradução sem valor" do
      create(:ad, :pending, category: vehicles)

      get admin_ads_path

      expect(response.body).not_to include("translation missing")
    end

    it "mostra a fila de pendentes por padrão" do
      pending_ad = create(:ad, :pending, category: vehicles, title: "Jipe pendente")
      create(:ad, category: vehicles, title: "Jipe aprovado")

      get admin_ads_path

      expect(response.body).to include(pending_ad.title)
      expect(response.body).not_to include("Jipe aprovado")
    end

    it "filtra pelo status pedido" do
      create(:ad, :pending, category: vehicles, title: "Jipe pendente")
      approved = create(:ad, category: vehicles, title: "Jipe aprovado")

      get admin_ads_path(status: "approved")

      expect(response.body).to include(approved.title)
      expect(response.body).not_to include("Jipe pendente")
    end

    # Status desconhecido na URL não pode virar consulta vazia sem explicação.
    it "cai na fila padrão quando o status é desconhecido" do
      pending_ad = create(:ad, :pending, category: vehicles, title: "Jipe pendente")

      get admin_ads_path(status: "inventado")

      expect(response.body).to include(pending_ad.title)
    end

    it "mostra tudo na aba de todos" do
      create(:ad, :pending, category: vehicles, title: "Jipe pendente")
      create(:ad, category: vehicles, title: "Jipe aprovado")

      get admin_ads_path(status: "all")

      expect(response.body).to include("Jipe pendente", "Jipe aprovado")
    end
  end

  # A fila é uma tabela como a de anunciantes: mesmas colunas ordenáveis, mesmo
  # filtro recolhível, mesmas caixas de seleção e mesmo rodapé de paginação.
  describe "a tabela" do
    before { create_list(:ad, 3, :pending, category: vehicles) }

    it "traz uma caixa de seleção por linha, apontando para o formulário em lote" do
      get admin_ads_path

      expect(response.body.scan(%(name="ad_ids[]")).size).to eq(3)
      expect(response.body).to include(%(form="bulk-review-form"))
    end

    it "oferece as colunas ordenáveis" do
      get admin_ads_path

      AdQueueFilter::SORTS.each_key do |key|
        expect(response.body).to include("sort=#{key}")
      end
    end

    it "marca a coluna que está ordenando para quem não vê a seta" do
      get admin_ads_path(sort: "price", dir: "asc")

      expect(response.body).to include(%(aria-sort="ascending"))
    end

    it "pagina com a contagem no rodapé" do
      create_list(:ad, Moderation::AdsController::PER_PAGE, :pending, category: vehicles)

      get admin_ads_path

      expect(response.body.scan("<tr id=\"ad-detail-").size).to eq(Moderation::AdsController::PER_PAGE)
      expect(response.body).to include(I18n.t("shared.pagination.next"))
    end

    it "carrega o filtro e a ordenação para a página seguinte" do
      create_list(:ad, Moderation::AdsController::PER_PAGE, :pending, category: vehicles)

      get admin_ads_path(sort: "price", dir: "asc")

      expect(response.body).to include("sort=price", "dir=asc", "page=2")
    end

    it "filtra pelo título sem sair da aba" do
      create(:ad, :pending, category: vehicles, title: "Troller T4 Único")

      get admin_ads_path(q: "único")

      expect(response.body).to include("Troller T4 Único")
      expect(response.body.scan(%(name="ad_ids[]")).size).to eq(1)
    end

    # As fotos abrem na própria linha, por link: sem JavaScript a moderação de
    # imagem continua alcançável.
    describe "linha de detalhe" do
      # let! e não let: a linha precisa existir antes do GET, não no momento em
      # que a expectativa a menciona.
      let!(:ad) { create(:ad, :pending, category: vehicles, image_count: 3) }

      it "vem fechada" do
        get admin_ads_path

        expect(response.body).to include(%(<tr id="ad-detail-#{ad.id}" hidden>))
      end

      it "abre pelo parâmetro da URL" do
        get admin_ads_path(open: ad.slug)

        expect(response.body).not_to include(%(<tr id="ad-detail-#{ad.id}" hidden>))
        expect(response.body).to include(I18n.t("admin.images.block"))
      end

      # A chave do rótulo já colidiu com a da mensagem de sucesso: em YAML a
      # última repetida vence, e o botão saía com o hash inteiro dentro.
      it "usa um rótulo de verdade nos botões de foto" do
        get admin_ads_path(open: ad.slug)

        expect(I18n.t("admin.images.block")).to be_a(String)
        expect(response.body).not_to include("success:")
      end
    end
  end

  describe "PATCH aprovar" do
    it "aprova e publica o anúncio" do
      ad = create(:ad, :pending, category: vehicles, image_count: 3)

      patch approve_admin_ad_path(ad)

      expect(ad.reload).to have_attributes(status: "approved", admin: admin)
      expect(ad.published_at).to be_present
    end

    it "passa a aparecer no portal depois de aprovado" do
      ad = create(:ad, :pending, category: vehicles, image_count: 3)
      patch approve_admin_ad_path(ad)

      get ad_path(ad)

      expect(response).to have_http_status(:ok)
    end

    it "recusa aprovar sem as fotos mínimas e avisa o moderador" do
      ad = create(:ad, :pending, category: vehicles)

      patch approve_admin_ad_path(ad)

      expect(ad.reload.status).to eq("pending")
      expect(flash[:alert]).to be_present
    end
  end

  describe "PATCH rejeitar" do
    it "rejeita e registra quem avaliou" do
      ad = create(:ad, :pending, category: vehicles)

      patch reject_admin_ad_path(ad)

      expect(ad.reload).to have_attributes(status: "rejected", admin: admin)
    end

    it "tira o anúncio do portal" do
      ad = create(:ad, category: vehicles)

      patch reject_admin_ad_path(ad)
      get ad_path(ad)

      expect(response).to have_http_status(:not_found)
      expect(Ad.published).to be_empty
    end
  end

  # As caixas de seleção da tabela. Um a um, e não update_all: aprovar passa
  # pela validação das fotos, e quem não passa precisa ser contado à parte.
  describe "PATCH avaliar em lote" do
    let(:complete) { create_list(:ad, 2, :pending, category: vehicles, image_count: 3) }

    def bulk(params)
      patch bulk_review_admin_ads_path, params: params
    end

    it "aprova e publica os marcados" do
      bulk(ad_ids: complete.map(&:id), to: "approve")

      expect(complete.map { |ad| ad.reload.status }).to all(eq("approved"))
      expect(complete.map(&:published_at)).to all(be_present)
    end

    it "registra quem avaliou" do
      bulk(ad_ids: complete.map(&:id), to: "approve")

      expect(complete.first.reload.admin).to eq(admin)
    end

    it "rejeita os marcados com o mesmo motivo" do
      bulk(ad_ids: complete.map(&:id), to: "reject", note: "Fotos fora do padrão.")

      expect(complete.map { |ad| ad.reload.status }).to all(eq("rejected"))
      expect(complete.first.reload.moderation_note).to eq("Fotos fora do padrão.")
    end

    # O motivo é cobrado na controller e não no formulário: o campo mora dentro
    # de um <dialog>, e um `required` ali faria o Chrome recusar em silêncio o
    # envio do botão de aprovar, que compartilha o mesmo formulário.
    it "recusa rejeitar sem motivo" do
      bulk(ad_ids: complete.map(&:id), to: "reject", note: "  ")

      expect(complete.map { |ad| ad.reload.status }).to all(eq("pending"))
      expect(flash[:alert]).to eq(I18n.t("admin.ads.bulk.note_required"))
    end

    it "avisa quando nada foi marcado" do
      bulk(to: "approve")

      expect(flash[:alert]).to eq(I18n.t("admin.ads.bulk.none"))
    end

    # Aprovar em massa não pode publicar anúncio incompleto: o que não passa
    # fica onde estava e é contado à parte.
    it "deixa para trás o que não pode ser aprovado" do
      incomplete = create(:ad, :pending, category: vehicles)

      bulk(ad_ids: complete.map(&:id) + [ incomplete.id ], to: "approve")

      expect(incomplete.reload.status).to eq("pending")
      expect(flash[:alert]).to eq(I18n.t("admin.ads.bulk.partial", count: 2, failed: 1))
    end

    it "avisa quando nenhum dos marcados passou" do
      incomplete = create(:ad, :pending, category: vehicles)

      bulk(ad_ids: [ incomplete.id ], to: "approve")

      expect(flash[:alert]).to eq(I18n.t("admin.ads.bulk.failed", count: 1))
    end

    # Voltar para a fila como ela estava é o que permite trabalhar a lista de
    # cima para baixo sem reconstruir filtro e ordenação a cada clique.
    it "volta para a fila com filtro, ordenação e página" do
      bulk(ad_ids: complete.map(&:id), to: "approve",
           list: { status: "pending", sort: "price", dir: "asc", page: "2" })

      expect(response).to redirect_to(admin_ads_path(status: "pending", sort: "price", dir: "asc", page: "2"))
    end

    it "exige sessão de moderador" do
      delete admin_logout_path

      bulk(ad_ids: complete.map(&:id), to: "approve")

      expect(complete.first.reload.status).to eq("pending")
    end
  end

  describe "sem sessão de moderador" do
    it "não deixa aprovar" do
      delete admin_logout_path
      ad = create(:ad, :pending, category: vehicles, image_count: 3)

      patch approve_admin_ad_path(ad)

      expect(ad.reload.status).to eq("pending")
    end
  end
end
