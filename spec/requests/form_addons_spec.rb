require "rails_helper"

# Os adornos que os formulários passaram a compartilhar: ícone no campo de
# e-mail, moeda colada no campo de dinheiro, "https://" colado no de endereço e
# o município num menu com busca.
RSpec.describe "Adornos dos formulários", type: :request do
  # O traço do envelope: se o ícone sair do campo, some daqui também.
  let(:envelope) { IconHelper::UI_ICONS.fetch(:envelope).first }

  describe "ícone no campo de e-mail" do
    it "aparece no login do anunciante" do
      get login_path

      expect(response.body).to include(envelope)
    end

    it "aparece no cadastro" do
      get signup_path

      expect(response.body).to include(envelope)
    end

    it "aparece no login da moderação" do
      get admin_login_path

      expect(response.body).to include(envelope)
    end

    it "aparece na newsletter da home" do
      get root_path

      expect(response.body).to include(envelope)
    end

    it "aparece no perfil do anunciante" do
      sign_in(create(:user))

      get edit_profile_path

      expect(response.body).to include(envelope)
    end

    it "aparece no filtro de anunciantes da moderação" do
      sign_in_admin(create(:admin))

      get admin_users_path

      expect(response.body).to include(envelope)
    end

    # O ícone ocupa a esquerda do campo; sem o recuo o texto passa por baixo dele.
    it "afasta o texto do campo do ícone" do
      get login_path

      expect(response.body).to include("pl-10")
    end
  end

  describe "moeda colada no campo de dinheiro" do
    before { sign_in(create(:user)) }

    it "mostra o R$ à esquerda do preço do anúncio" do
      get new_account_ad_path

      expect(response.body).to include(%(<option value="BRL">#{I18n.t("shared.money.brl")}</option>))
    end

    # O portal negocia só em real: o seletor diz em que unidade o número está e
    # não é enviado junto — quem converte para os centavos inteiros é o modelo.
    it "não envia a moeda no formulário" do
      get new_account_ad_path

      expect(response.body).not_to include(%(name="currency"))
    end

    it "mostra o R$ à esquerda do valor da proposta" do
      get ad_path(create(:ad))

      expect(response.body).to include(%(<option value="BRL">#{I18n.t("shared.money.brl")}</option>))
    end
  end

  describe "https:// colado no campo de endereço" do
    before { sign_in_admin(create(:admin)) }

    it "aparece no site do evento" do
      get new_admin_event_path

      expect(response.body).to include("https://")
    end

    # O valor gravado já traz o esquema; repeti-lo no campo mostraria
    # "https://https://exemplo.com.br".
    it "não repete o esquema no valor do campo" do
      event = create(:event, :with_url)

      get edit_admin_event_path(event)

      expect(response.body).to include(%(value="exemplo.com.br/evento"))
      expect(response.body).not_to include(%(value="https://exemplo.com.br/evento"))
    end
  end

  describe "município num menu com busca" do
    def city_menu?(body)
      body.include?(%(data-controller="city-select")) && body.include?(%(data-city-select-target="search"))
    end

    it "aparece no cadastro" do
      get signup_path

      expect(city_menu?(response.body)).to be(true)
    end

    it "aparece no perfil do anunciante" do
      sign_in(create(:user))

      get edit_profile_path

      expect(city_menu?(response.body)).to be(true)
    end

    it "aparece no formulário de evento da moderação" do
      sign_in_admin(create(:admin))

      get new_admin_event_path

      expect(city_menu?(response.body)).to be(true)
    end

    it "aparece no filtro da vitrine" do
      get ads_path

      expect(city_menu?(response.body)).to be(true)
    end

    # Na vitrine as opções são as cidades que têm anúncio, e não os 5.571 do
    # país: a lista vem embutida e o menu filtra no próprio navegador.
    it "embute as cidades com anúncio no filtro da vitrine, sem consultar o endpoint" do
      create(:ad, city: "Campo Largo", state: "PR")

      get ads_path

      expect(response.body).to include(%(data-city-select-target="options"))
      expect(response.body).to include("Campo Largo")
      expect(response.body).to include(%(data-city-select-url-value=""))
    end

    it "guarda o município no mesmo campo de texto de antes" do
      sign_in(create(:user))

      get edit_profile_path

      expect(response.body).to include(%(name="user[city]"))
    end
  end
end
