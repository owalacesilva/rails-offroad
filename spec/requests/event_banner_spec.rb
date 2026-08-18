require "rails_helper"

RSpec.describe "Banner de evento em destaque", type: :request do
  describe "home" do
    it "mostra o banner do evento marcado" do
      event = create(:event, title: "Trilhão em Destaque", featured: true)

      get root_path

      expect(response.body).to include(I18n.t("home.event_banner.label"), event.title)
    end

    it "não mostra banner nenhum sem destaque marcado" do
      create(:event)

      get root_path

      expect(response.body).not_to include(I18n.t("home.event_banner.label"))
    end

    # Destaque de evento que já passou não vira banner.
    it "ignora destaque de evento vencido" do
      create(:event, :past, title: "Já aconteceu", featured: true)

      get root_path

      expect(response.body).not_to include(I18n.t("home.event_banner.label"))
    end

    it "leva ao site do organizador" do
      create(:event, :with_url, featured: true)

      get root_path

      expect(response.body).to include("https://exemplo.com.br/evento", I18n.t("home.event_banner.cta"))
    end

    it "não deixa nenhuma chave de tradução sem valor" do
      create(:event, featured: true)

      get root_path

      expect(response.body).not_to include("translation missing")
    end
  end

  describe "exclusividade" do
    # O banner é um só: marcar um destaque desmarca o anterior, venha a marcação
    # do feature! ou da caixa de seleção do formulário.
    it "marcar um segundo desmarca o primeiro" do
      first = create(:event, featured: true)
      second = create(:event)

      second.update!(featured: true)

      expect(first.reload).not_to be_featured
      expect(Event.featured.count).to eq(1)
    end

    it "o destaque válido é o que vira banner" do
      create(:event, featured: true)
      second = create(:event)

      second.update!(featured: true)

      expect(Event.banner).to eq(second)
    end

    it "salvar sem mexer no destaque não desmarca ninguém" do
      featured = create(:event, featured: true)
      other = create(:event)

      other.update!(title: "Outro nome")

      expect(featured.reload).to be_featured
    end
  end

  describe "gestão" do
    let(:admin) { create(:admin) }

    before { sign_in_admin(admin) }

    it "o formulário oferece a caixa de destaque" do
      get new_admin_event_path

      expect(response.body).to include('name="event[featured]"', I18n.t("admin.events.form.featured_hint"))
    end

    it "marca o destaque pelo formulário" do
      post admin_events_path, params: {
        event: { title: "Trilhão", starts_on: 10.days.from_now.to_date, city: "Curitiba", state: "PR", featured: "1" }
      }

      expect(Event.last).to be_featured
    end
  end
end
