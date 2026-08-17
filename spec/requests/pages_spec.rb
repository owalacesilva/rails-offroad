require "rails_helper"

RSpec.describe "Páginas institucionais", type: :request do
  # Caminho em português, action em inglês — a convenção do projeto. O literal
  # fica inline porque é lido na montagem dos grupos, antes de existir exemplo
  # onde um let pudesse morar.
  {
    "/sobre-nos" => "about",
    "/como-anunciar" => "how_to_advertise",
    "/politica-de-privacidade" => "privacy",
    "/termos-de-uso" => "terms"
  }.each do |path, page|
    describe "GET #{path}" do
      before { get path }

      it "responde com sucesso sem exigir login" do
        expect(response).to have_http_status(:ok)
      end

      it "mostra o título da página" do
        expect(response.body).to include(I18n.t("pages.#{page}.title"))
      end

      it "monta o corpo a partir das seções do locale" do
        headings = I18n.t("pages.#{page}.sections").map { |section| section[:heading] }

        expect(headings).not_to be_empty
        expect(response.body).to include(ERB::Util.html_escape(headings.first))
      end

      it "não deixa nenhuma chave de tradução sem valor" do
        expect(response.body).not_to include("translation missing")
      end

      it "responde também em en-US" do
        get path, params: { locale: "en-US" }

        expect(response.body).to include(I18n.t("pages.#{page}.title", locale: :"en-US"))
        expect(response.body).not_to include("translation missing")
      end
    end
  end

  describe "passo a passo de como anunciar" do
    it "numera os passos declarados no locale" do
      get "/como-anunciar"

      steps = I18n.t("pages.how_to_advertise.steps")

      expect(steps.size).to be >= 3
      expect(response.body).to include(ERB::Util.html_escape(steps.first[:title]))
    end
  end

  describe "data de revisão" do
    it "aparece na política de privacidade" do
      get "/politica-de-privacidade"

      expect(response.body).to include(I18n.l(PagesController::LAST_UPDATED_ON, format: :long))
    end

    # Só documento normativo tem data de revisão; página de apresentação não.
    it "não aparece em sobre nós" do
      get "/sobre-nos"

      expect(response.body).not_to include(I18n.t("pages.updated", date: ""))
    end
  end

  describe "links no rodapé" do
    it "leva às quatro páginas a partir de qualquer página do portal" do
      get root_path

      expect(response.body).to include(about_path, how_to_advertise_path, terms_of_use_path, privacy_policy_path)
    end
  end
end
