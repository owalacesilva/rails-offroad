require "rails_helper"

RSpec.describe "Detalhe do anúncio", type: :request do
  let(:vehicles) { create(:category, :vehicles) }
  let(:parts) { create(:category, :parts) }

  let(:user) do
    create(:user, name: "Garagem Trilha Livre", city: "Curitiba", state: "PR", phone: "5541988770011")
  end

  let(:ad) do
    create(:ad, :with_specs, image_count: 3,
                title: "Jeep Wrangler Rubicon", category: vehicles, user: user,
                description: "Revisões sempre em concessionária.",
                specs: { "engine" => "3.6 V6", "mileage_km" => 48_000 })
  end

  describe "GET /anuncios/:id" do
    before { get ad_path(ad) }

    it "responde com sucesso" do
      expect(response).to have_http_status(:ok)
    end

    it "não deixa nenhuma chave de tradução sem valor" do
      expect(response.body).not_to include("translation missing")
    end

    it "mostra o nome do anunciante" do
      expect(response.body).to include("Garagem Trilha Livre")
    end

    it "mostra a localização do anunciante" do
      expect(response.body).to include(user.location)
    end

    it "monta o link do WhatsApp com o telefone do anunciante" do
      expect(response.body).to include("https://wa.me/5541988770011")
    end

    it "leva o título do anúncio na mensagem do WhatsApp" do
      expect(response.body).to include(CGI.escape(ad.title))
    end

    it "renderiza uma miniatura por foto" do
      expect(response.body.scan('data-gallery-target="thumb"').size).to eq(3)
    end

    it "renderiza o modal de proposta" do
      expect(response.body).to include("<dialog").and include('data-action="modal#open"')
    end

    it "mantém o modal fechado quando não há erro" do
      expect(response.body).to include('data-modal-open-value="false"')
    end

    it "mostra a descrição" do
      expect(response.body).to include("Revisões sempre em concessionária.")
    end

    it "traduz o rótulo das especificações" do
      expect(response.body).to include(I18n.t("ads.specifications.mileage_km"))
    end

    it "formata a quilometragem com separador de milhar" do
      expect(response.body).to include("48.000 km")
    end
  end

  describe "galeria sem foto" do
    # A validação de 3 a 10 fotos impede publicar sem foto, então o caminho só
    # é alcançável se as fotos sumirem depois. A view precisa aguentar mesmo assim.
    it "mostra o aviso em vez de quebrar" do
      orphan = create(:ad, category: vehicles, user: user)
      orphan.ad_images.destroy_all

      get ad_path(orphan)

      expect(response.body).to include(I18n.t("ads.show.gallery.empty"))
    end
  end

  describe "anúncios relacionados" do
    it "traz outro anúncio da mesma categoria" do
      sibling = create(:ad, title: "Troller T4", category: vehicles, user: user)

      get ad_path(ad)

      expect(response.body).to include(sibling.title)
    end

    it "não traz anúncio de outra categoria" do
      other = create(:ad, title: "Snorkel Safari", category: parts, user: user)

      get ad_path(ad)

      expect(response.body).not_to include(other.title)
    end

    it "avisa quando não há relacionados" do
      get ad_path(ad)

      expect(response.body).to include(I18n.t("ads.show.no_related"))
    end
  end

  describe "locale" do
    it "responde em en-US quando pedido" do
      get ad_path(ad, locale: "en-US")

      expect(response.body).to include(I18n.t("ads.show.propose", locale: :"en-US"))
    end
  end
end
