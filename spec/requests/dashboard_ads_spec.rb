require "rails_helper"

RSpec.describe "Meus Anúncios", type: :request do
  let(:user) { create(:user) }
  let(:vehicles) { create(:category, :vehicles) }

  before { sign_in(user) }

  describe "GET /anunciante/anuncios" do
    it "responde com sucesso" do
      get account_ads_path

      expect(response).to have_http_status(:ok)
    end

    it "não deixa nenhuma chave de tradução sem valor" do
      create(:ad, user: user, category: vehicles)
      create(:ad, :pending, user: user, category: vehicles)

      get account_ads_path

      expect(response.body).not_to include("translation missing")
    end

    it "lista os anúncios do próprio anunciante" do
      mine = create(:ad, user: user, category: vehicles, title: "Meu Jipe")

      get account_ads_path

      expect(response.body).to include(mine.title)
    end

    it "não mostra anúncio de outro anunciante" do
      create(:ad, user: create(:user), category: vehicles, title: "Jipe alheio")

      get account_ads_path

      expect(response.body).not_to include("Jipe alheio")
    end

    # O ponto da página: anúncio parado na moderação não some, aparece marcado.
    it "mostra também o anúncio que ainda não foi aprovado" do
      waiting = create(:ad, :pending, user: user, category: vehicles, title: "Aguardando")

      get account_ads_path

      expect(response.body).to include(waiting.title)
      expect(response.body).to include(I18n.t("ads.statuses.pending"))
    end

    it "explica por que o anúncio rejeitado não está no ar" do
      create(:ad, :rejected, user: user, category: vehicles)

      get account_ads_path

      expect(response.body).to include(I18n.t("dashboard.ads_index.hints.rejected"))
    end

    it "filtra pela situação pedida" do
      create(:ad, user: user, category: vehicles, title: "Jipe aprovado")
      create(:ad, :pending, user: user, category: vehicles, title: "Jipe pendente")

      get account_ads_path(status: "pending")

      expect(response.body).to include("Jipe pendente")
      expect(response.body).not_to include("Jipe aprovado")
    end

    it "mostra tudo quando a situação pedida é desconhecida" do
      create(:ad, user: user, category: vehicles, title: "Jipe aprovado")
      create(:ad, :pending, user: user, category: vehicles, title: "Jipe pendente")

      get account_ads_path(status: "inventado")

      expect(response.body).to include("Jipe aprovado").and include("Jipe pendente")
    end

    it "só oferece o link do portal para anúncio aprovado" do
      create(:ad, :pending, user: user, category: vehicles)

      get account_ads_path

      expect(response.body).to include(I18n.t("dashboard.ads_index.not_public"))
    end
  end

  describe "GET /anunciante/anuncios/novo" do
    it "responde com sucesso" do
      get new_account_ad_path

      expect(response).to have_http_status(:ok)
    end

    it "não deixa nenhuma chave de tradução sem valor" do
      get new_account_ad_path

      expect(response.body).not_to include("translation missing")
    end

    it "já vem com a cidade e o estado do cadastro" do
      get new_account_ad_path

      expect(response.body).to include(%(value="#{user.city}"))
    end

    describe "categoria em emblemas" do
      before do
        create(:category, :bikes)
        get new_account_ad_path
      end

      # Emblemas no lugar do select, mas radios por baixo: é o que mantém o
      # grupo navegável por teclado e legível por leitor de tela.
      it "oferece um radio por categoria, e não um select" do
        expect(response.body.scan(/type="radio" value="[^"]+" name="ad\[category_id\]"/).size).to eq(Category.count)
        expect(response.body).not_to include('name="ad[category_id]" id="ad_category_id"')
      end

      it "esconde o radio e pinta o rótulo pelo estado marcado" do
        expect(response.body).to include('class="peer sr-only"', "peer-checked:border-brand-500")
      end
    end

    describe "município por autocomplete" do
      before { get new_account_ad_path }

      # Os 5.571 municípios não podem sair todos no HTML: a lista chega por
      # requisição, filtrada pela UF.
      it "não embute a lista de municípios na página" do
        create(:city, :curitiba)

        get new_account_ad_path

        expect(response.body).not_to include("<option value=\"Curitiba\"")
      end

      it "aponta o campo para o endpoint de municípios" do
        expect(response.body).to include(%(data-city-autocomplete-url-value="#{cities_path}"))
      end

      it "liga o campo de cidade a um datalist" do
        expect(response.body).to include('list="ad-city-options"', '<datalist id="ad-city-options"')
      end
    end

    describe "fotos por Dropzone" do
      before { get new_account_ad_path }

      it "publica o endpoint de upload e os limites para o componente" do
        expect(response.body).to include(
          %(data-photo-upload-url-value="#{account_ad_photos_path}"),
          %(data-photo-upload-min-value="#{Ad::IMAGE_COUNT.min}"),
          %(data-photo-upload-width-value="#{Dashboard::AdPhotosController::MAX_WIDTH}")
        )
      end

      it "não oferece mais o campo de URLs digitadas" do
        expect(response.body).not_to include('name="photo_urls"')
      end
    end

    describe "descrição com formatação" do
      before { get new_account_ad_path }

      it "oferece os cinco controles pedidos" do
        commands = response.body.scan(/data-rich-text-command-param="([^"]+)"/).flatten

        expect(commands).to contain_exactly("bold", "italic", "insertUnorderedList", "insertOrderedList", "formatBlock")
      end

      it "usa H3 no controle de título" do
        expect(response.body).to include('data-rich-text-value-param="h3"')
      end

      # O textarea continua sendo o campo de verdade: é ele que vai no POST, e
      # é o que sobra sem JavaScript.
      it "mantém o textarea como campo do formulário" do
        expect(response.body).to include('name="ad[description]"')
      end
    end

    describe "botão de publicar" do
      before { get new_account_ad_path }

      it "nasce desabilitado, à espera do mínimo de fotos" do
        expect(response.body).to match(/<button type="submit"[^>]*disabled/)
      end

      it "traz o rótulo de carregando e o disco girando" do
        expect(response.body).to include(
          %(data-submit-sending-value="#{I18n.t('dashboard.ads_new.sending')}"),
          'data-submit-target="spinner"'
        )
      end
    end

    it "não limita o ano do formulário a um ano futuro" do
      get new_account_ad_path

      expect(response.body).to include(%(max="#{Date.current.year}"))
    end
  end

  describe "POST /anunciante/anuncios" do
    # As fotos já subiram pelo Dropzone antes do envio; o formulário manda só os
    # signed_ids dos blobs, na ordem da fila.
    let(:signed_ids) { photo_signed_ids(Ad::IMAGE_COUNT.min) }
    let(:valid_attributes) do
      { title: "Jeep Wrangler de Teste", category_id: vehicles.id, price: "45.000,50",
        year: 2019, city: "Curitiba", state: "PR", description: "Bem conservado." }
    end

    # Chaves explícitas na chamada: com o keyword `photos:` na assinatura, um
    # hash sem chaves viraria keyword argument em vez de posicional.
    def submit(overrides = {}, photos: signed_ids)
      post account_ads_path, params: { ad: valid_attributes.merge(overrides), photo_signed_ids: photos }
    end

    it "cria o anúncio do próprio anunciante" do
      expect { submit }.to change(user.ads, :count).by(1)
    end

    it "entra na fila de moderação, não no portal" do
      submit

      expect(Ad.last).to be_pending
      expect(Ad.published).to be_empty
    end

    it "aceita o preço no formato brasileiro" do
      # "45.000,50" com o ponto de milhar; sem tratar, viraria 45.
      submit

      expect(Ad.last.price).to eq(45_000.50)
    end

    it "guarda as fotos na ordem em que foram enviadas" do
      submit

      expect(Ad.last.ad_images.ordered.pluck(:sort_order)).to eq((0...Ad::IMAGE_COUNT.min).to_a)
    end

    it "anexa cada foto ao blob que o upload criou" do
      submit

      expect(Ad.last.ad_images.map { |image| image.file.attached? }).to all(be(true))
    end

    # Id adulterado não estoura: some da lista, e quem reclama é a contagem.
    it "ignora signed_id inválido" do
      expect { submit(photos: signed_ids.first(2) + [ "nao-e-um-signed-id" ]) }.not_to change(Ad, :count)
    end

    it "redireciona para a lista com aviso de moderação" do
      submit

      expect(response).to redirect_to(account_ads_path)
    end

    it "recusa menos fotos que o mínimo, que a moderação exigiria depois" do
      expect { submit(photos: signed_ids.first(Ad::IMAGE_COUNT.min - 1)) }.not_to change(Ad, :count)
    end

    it "explica por que recusou" do
      submit(photos: [])

      expect(response.body).to include(I18n.t("activerecord.errors.models.ad.attributes.ad_images.invalid_count",
                                              min: Ad::IMAGE_COUNT.min, max: Ad::IMAGE_COUNT.max))
    end

    it "recusa preço zerado" do
      expect { submit({ price: "0" }) }.not_to change(Ad, :count)
    end

    it "devolve o formulário com 422 quando algo falha" do
      submit({ title: "" })

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "ignora um user_id vindo do formulário" do
      other = create(:user)

      post account_ads_path, params: { ad: valid_attributes.merge(user_id: other.id), photo_signed_ids: signed_ids }

      expect(Ad.last.user).to eq(user)
    end
  end

  it "exige sessão" do
    delete logout_path

    get account_ads_path

    expect(response).to redirect_to(login_path)
  end

  it "exige sessão para publicar" do
    delete logout_path

    get new_account_ad_path

    expect(response).to redirect_to(login_path)
  end
end
