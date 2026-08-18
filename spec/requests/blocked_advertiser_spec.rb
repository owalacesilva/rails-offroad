require "rails_helper"

# Bloquear ou inativar um anunciante tem de valer em três lugares: no login, na
# sessão que já estava aberta e na vitrine pública.
RSpec.describe "Anunciante fora de atividade", type: :request do
  let(:blocked) { create(:user, status: :blocked) }
  let(:inactive) { create(:user, status: :inactive) }

  describe "login" do
    it "recusa o anunciante bloqueado" do
      sign_in(blocked)

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "recusa o anunciante inativo" do
      sign_in(inactive)

      expect(response).to have_http_status(:unprocessable_content)
    end

    # A mensagem é a mesma da senha errada: dizer "conta bloqueada" para quem
    # chutou um e-mail revelaria que aquele e-mail existe.
    it "não conta que a conta existe" do
      sign_in(blocked)

      expect(response.body).to include(I18n.t("sessions.create.failure"))
      expect(response.body).not_to include(blocked.email)
    end

    it "continua aceitando o anunciante ativo" do
      sign_in(create(:user))

      expect(response).to redirect_to(root_path)
    end
  end

  describe "sessão já aberta" do
    # Bloquear alguém não pode esperar o próximo login para valer.
    it "para de valer assim que o anunciante é bloqueado" do
      user = create(:user)
      sign_in(user)
      user.blocked!

      get account_path

      expect(response).to redirect_to(login_path)
    end
  end

  describe "vitrine" do
    let(:vehicles) { create(:category, :vehicles) }

    it "tira os anúncios do anunciante bloqueado do portal" do
      ad = create(:ad, user: blocked, category: vehicles, title: "Jeep de Anunciante Bloqueado")

      get ads_path

      expect(response.body).not_to include(ad.title)
    end

    it "devolve 404 na página do anúncio dele" do
      ad = create(:ad, user: blocked, category: vehicles)

      get ad_path(ad)

      expect(response).to have_http_status(:not_found)
    end

    it "mantém no ar os anúncios de quem está ativo" do
      ad = create(:ad, category: vehicles, title: "Jeep de Anunciante Ativo")

      get ads_path

      expect(response.body).to include(ad.title)
    end
  end
end
