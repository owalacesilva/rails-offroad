require "rails_helper"

RSpec.describe "Home", type: :request do
  let(:vehicles) { create(:category, :vehicles) }

  # As duas fileiras de recentes e a régua de mais vistos usam esta mesma grade;
  # contar quantas aparecem num recorte é como se verifica a divisão em fileiras.
  let(:card_row) { "grid-cols-2 gap-4 sm:grid-cols-3 lg:grid-cols-6" }

  # A home é uma página só com seis seções: recortar pelo título é o que deixa
  # afirmar coisas sobre uma delas sem contar os cards das outras.
  def section_between(first_key, last_key)
    body = response.body

    body[/#{Regexp.escape(I18n.t(first_key))}(.*?)#{Regexp.escape(I18n.t(last_key))}/m, 1]
  end

  describe "GET /" do
    before do
      create_list(:ad, 6, category: vehicles)
      get root_path
    end

    it "responde com sucesso" do
      expect(response).to have_http_status(:ok)
    end

    it "não deixa nenhuma chave de tradução sem valor" do
      expect(response.body).not_to include("translation missing")
    end

    it "leva o card de anúncio para a listagem já filtrada" do
      expect(response.body).to include(ads_path(category: "veiculos-4x4"))
    end
  end

  # A ordem foi pedida assim e não é acidental: recentes, galeria, mais vistos,
  # agenda, newsletter e galeria de novo.
  describe "ordem das seções" do
    before do
      create_list(:ad, 3, category: vehicles)
      create(:event)
      get root_path
    end

    it "monta as seis seções na ordem combinada" do
      positions = [
        I18n.t("home.ads.title"),
        I18n.t("home.gallery.title"),
        I18n.t("home.most_viewed.title"),
        I18n.t("home.events.title"),
        I18n.t("home.newsletter.title"),
        I18n.t("home.gallery.more_title")
      ].map { |title| response.body.index(title) }

      expect(positions).to all(be_present)
      expect(positions).to eq(positions.sort)
    end

    # A grade de categorias saiu da home; as categorias seguem no header e no rodapé.
    it "não traz mais a grade de categorias" do
      expect(response.body).not_to include(I18n.t("home.categories.title", default: "Navegue por categoria"))
    end
  end

  describe "anúncios recentes" do
    it "mostra no máximo doze, mesmo com mais anúncios publicados" do
      create_list(:ad, 15, category: vehicles)

      get root_path

      section = section_between("home.ads.title", "home.gallery.title")

      expect(section.scan("<article").size).to eq(HomeController::RECENT_ROW * 2)
    end

    it "divide os doze em duas fileiras de seis" do
      create_list(:ad, 15, category: vehicles)

      get root_path

      section = section_between("home.ads.title", "home.gallery.title")

      expect(section.scan(card_row).size).to eq(2)
      expect(HomeController::RECENT_ROW).to eq(6)
    end

    it "deixa de fora o anúncio que ainda não passou pela moderação" do
      pendente = create(:ad, :pending, category: vehicles, title: "Jipe Aguardando Moderação")

      get root_path

      expect(response.body).not_to include(ad_path(pendente))
    end

    it "explica a vitrine vazia em vez de mostrar um buraco" do
      get root_path

      expect(response.body).to include(I18n.t("home.ads.empty"))
    end
  end

  describe "mais vistos" do
    it "ordena pelo contador de visualizações, não pela data" do
      create(:ad, category: vehicles, title: "Menos Visto", views_count: 3, published_at: 1.hour.ago)
      create(:ad, category: vehicles, title: "Mais Visto", views_count: 900, published_at: 5.days.ago)

      get root_path

      section = response.body.split(I18n.t("home.most_viewed.title")).last

      expect(section.index("Mais Visto")).to be < section.index("Menos Visto")
    end

    it "mostra no máximo doze, numa régua só" do
      create_list(:ad, 14, category: vehicles)

      get root_path

      section = section_between("home.most_viewed.title", "home.events.title")

      expect(section.scan("<article").size).to eq(HomeController::MOST_VIEWED_LIMIT)
      expect(section.scan(card_row).size).to eq(1)
    end
  end

  describe "galeria de fotos" do
    it "usa as fotos dos anúncios publicados e leva ao anúncio" do
      ad = create(:ad, category: vehicles, image_count: 3)

      get root_path

      expect(response.body).to include(ad.ad_images.first.file_url)
      expect(response.body).to include(ad_path(ad))
    end

    # As duas galerias saem da mesma consulta, fatiada: a de baixo continua de
    # onde a de cima parou em vez de repetir foto.
    it "não repete foto entre a galeria de cima e a de baixo" do
      create_list(:ad, 10, category: vehicles)

      get root_path

      top = section_between("home.gallery.title", "home.most_viewed.title").scan(%r{/seed-images/[\w-]+\.png})
      bottom = response.body.split(I18n.t("home.gallery.more_title")).last.scan(%r{/seed-images/[\w-]+\.png})

      expect(top.size).to eq(HomeController::GALLERY_SIZE)
      expect(top & bottom).to be_empty
    end

    it "explica a galeria vazia" do
      get root_path

      expect(response.body).to include(I18n.t("home.gallery.empty"))
    end
  end

  describe "próximos eventos" do
    it "mostra no máximo quatro, do mais próximo para o mais distante" do
      6.times { |index| create(:event, starts_on: (index + 1).weeks.from_now.to_date) }

      get root_path

      shown = Event.upcoming.limit(HomeController::EVENTS_LIMIT)

      expect(shown.size).to eq(4)
      shown.each { |event| expect(response.body).to include(ERB::Util.html_escape(event.title)) }
      expect(response.body).not_to include(ERB::Util.html_escape(Event.upcoming.last.title))
    end

    it "deixa de fora o evento que já passou" do
      passado = create(:event, :past, title: "Trilhão do Ano Passado")

      get root_path

      expect(response.body).not_to include(passado.title)
    end

    it "explica a agenda vazia" do
      get root_path

      expect(response.body).to include(I18n.t("home.events.empty"))
    end
  end

  describe "newsletter" do
    it "publica o formulário com a âncora para onde o POST redireciona" do
      get root_path

      expect(response.body).to include('id="newsletter"', "action=\"#{newsletter_subscription_path}\"")
    end

    it "aponta para a política de privacidade" do
      get root_path

      expect(response.body).to include(privacy_policy_path)
    end
  end

  describe "botão Anunciar" do
    it "pulsa devagar para se destacar da barra" do
      get root_path

      expect(response.body).to include("animate-pulse-slow")
    end
  end

  describe "busca do hero" do
    before { create(:ad, category: vehicles, title: "Suzuki Jimny Sierra 1.5 4x4") }

    it "envia a busca para a listagem" do
      get root_path

      expect(response.body).to include('action="/anuncios"', 'name="q"', 'name="category"')
    end

    it "oferece atalhos que são buscas de verdade" do
      get root_path

      expect(response.body).to include(ads_path(q: "Jimny"))
    end

    # Afirmar só a presença passaria mesmo sem filtro nenhum, porque os dois
    # anúncios cabem na primeira página: a ausência do outro é a prova.
    it "o atalho filtra a listagem de verdade" do
      create(:ad, category: vehicles, title: "Ford Ranger Raptor 2.0")

      get ads_path(q: "Jimny")

      expect(response.body).to include("Suzuki Jimny Sierra 1.5 4x4")
      expect(response.body).not_to include("Ford Ranger Raptor 2.0")
    end
  end

  describe "seleção de locale" do
    it "usa pt-BR por padrão" do
      get root_path

      expect(response.body).to include(I18n.t("home.ads.title", locale: :"pt-BR"))
    end

    it "aceita en-US pelo parâmetro da URL" do
      get root_path(locale: "en-US")

      expect(response.body).to include(I18n.t("home.ads.title", locale: :"en-US"))
    end

    it "ignora o Accept-Language do navegador e mantém o padrão" do
      # O portal é brasileiro: só ?locale= tira a interface do pt-BR.
      get root_path, headers: { "Accept-Language" => "en-US,en;q=0.9" }

      expect(response.body).to include(I18n.t("home.ads.title", locale: :"pt-BR"))
    end

    it "atende o ?locale= mesmo com o navegador pedindo outra coisa" do
      get root_path(locale: "en-US"), headers: { "Accept-Language" => "pt-BR,pt;q=0.9" }

      expect(response.body).to include(I18n.t("home.ads.title", locale: :"en-US"))
    end

    it "ignora locale não suportado e cai no padrão" do
      get root_path(locale: "xx-YY")

      expect(response.body).to include(I18n.t("home.ads.title", locale: :"pt-BR"))
    end

    it "não oferece :en, que existe apenas como base de fallback de en-US" do
      get root_path(locale: "en")

      expect(response.body).to include(I18n.t("home.ads.title", locale: :"pt-BR"))
    end
  end
end
