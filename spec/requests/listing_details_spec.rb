require "rails_helper"

RSpec.describe "Detalhe do anúncio", type: :request do
  let(:vehicles) { create(:category, :vehicles) }
  let(:parts) { create(:category, :parts) }

  let(:advertiser) do
    create(:advertiser, name: "Garagem Trilha Livre", city: "Curitiba", state: "PR", phone: "5541988770011")
  end

  let(:listing) do
    create(:listing, :with_photos, photo_count: 3,
                                   title: "Jeep Wrangler Rubicon", category: vehicles, advertiser: advertiser,
                                   description: "Revisões sempre em concessionária.",
                                   specifications: { "engine" => "3.6 V6", "mileage_km" => 48_000 })
  end

  describe "GET /anuncios/:id" do
    before { get listing_path(listing) }

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
      expect(response.body).to include(advertiser.location)
    end

    it "monta o link do WhatsApp com o telefone do anunciante" do
      expect(response.body).to include("https://wa.me/5541988770011")
    end

    it "leva o título do anúncio na mensagem do WhatsApp" do
      expect(response.body).to include(CGI.escape(listing.title))
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
      expect(response.body).to include(I18n.t("listings.specifications.mileage_km"))
    end

    it "formata a quilometragem com separador de milhar" do
      expect(response.body).to include("48.000 km")
    end
  end

  describe "galeria sem foto" do
    it "mostra o aviso em vez de quebrar" do
      get listing_path(create(:listing, category: vehicles, advertiser: advertiser))

      expect(response.body).to include(I18n.t("listings.show.gallery.empty"))
    end
  end

  describe "anúncios relacionados" do
    it "traz outro anúncio da mesma categoria" do
      sibling = create(:listing, title: "Troller T4", category: vehicles, advertiser: advertiser)

      get listing_path(listing)

      expect(response.body).to include(sibling.title)
    end

    it "não traz anúncio de outra categoria" do
      other = create(:listing, title: "Snorkel Safari", category: parts, advertiser: advertiser)

      get listing_path(listing)

      expect(response.body).not_to include(other.title)
    end

    it "avisa quando não há relacionados" do
      get listing_path(listing)

      expect(response.body).to include(I18n.t("listings.show.no_related"))
    end
  end

  describe "locale" do
    it "responde em en-US quando pedido" do
      get listing_path(listing, locale: "en-US")

      expect(response.body).to include(I18n.t("listings.show.propose", locale: :"en-US"))
    end
  end
end
