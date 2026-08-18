require "rails_helper"

# Entrar com Google ou Facebook. Marcado com :oauth para o exemplo rodar com as
# credenciais no ambiente — sem elas o provedor não existe (ver spec/support/oauth.rb).
RSpec.describe "Entrar por provedor", type: :request do
  let(:profile) do
    { sub: "1078", email: "piloto@gmail.com", email_verified: true, name: "Piloto de Trilha" }
  end

  def stub_google(profile_body: profile, token_status: 200)
    stub_request(:post, "https://oauth2.googleapis.com/token")
      .to_return(status: token_status, body: { access_token: "token" }.to_json,
                 headers: { "Content-Type" => "application/json" })
    stub_request(:get, "https://openidconnect.googleapis.com/v1/userinfo")
      .to_return(status: 200, body: profile_body.to_json, headers: { "Content-Type" => "application/json" })
  end

  # O state fica na sessão; a única forma de o spec conhecê-lo é começando o
  # fluxo como o botão começa.
  def start_and_callback(params = {})
    post oauth_authorization_path(provider: "google")
    state = response.headers["Location"][/state=([^&]+)/, 1]

    get oauth_callback_path(provider: "google"), params: { code: "codigo", state: state }.merge(params)
  end

  describe "provedor não configurado" do
    it "não mostra botão no login" do
      get login_path

      expect(response.body).not_to include(I18n.t("shared.oauth.sign_in", provider: "Google"))
    end

    # Provedor sem credencial e provedor inexistente devolvem a mesma coisa: de
    # fora, as duas situações são "essa rota não existe".
    it "não expõe a rota de início" do
      post oauth_authorization_path(provider: "google")

      expect(response).to have_http_status(:not_found)
    end

    it "não expõe a rota de retorno" do
      get oauth_callback_path(provider: "google")

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "com provedor configurado", :oauth do
    it "mostra os dois botões no login" do
      get login_path

      expect(response.body).to include(I18n.t("shared.oauth.sign_in", provider: "Google"))
      expect(response.body).to include(I18n.t("shared.oauth.sign_in", provider: "Facebook"))
    end

    it "mostra os botões no cadastro" do
      get signup_path

      expect(response.body).to include(I18n.t("shared.oauth.sign_up", provider: "Google"))
    end

    # Provedor que a rota não conhece nem chega ao controller: a constraint
    # barra antes.
    it "não roteia provedor desconhecido" do
      post "/entrar/orkut"

      expect(response).to have_http_status(:not_found)
    end

    describe "POST /entrar/:provider" do
      it "manda para o provedor" do
        post oauth_authorization_path(provider: "google")

        expect(response).to redirect_to(%r{\Ahttps://accounts\.google\.com/o/oauth2/v2/auth\?})
      end

      it "leva a URL de retorno do próprio portal" do
        post oauth_authorization_path(provider: "google")

        expect(response.headers["Location"]).to include(CGI.escape(oauth_callback_url(provider: "google")))
      end
    end

    describe "quem ainda não tem conta" do
      before { stub_google }

      # O provedor dá nome e e-mail; telefone, cidade e UF só a pessoa sabe, e
      # são obrigatórios num portal de classificados.
      it "é levado ao cadastro para completar" do
        start_and_callback

        expect(response).to redirect_to(signup_path)
      end

      it "não cria conta pela metade" do
        expect { start_and_callback }.not_to change(User, :count)
      end

      it "chega ao formulário com nome e e-mail preenchidos" do
        start_and_callback
        follow_redirect!

        expect(response.body).to include("Piloto de Trilha", "piloto@gmail.com")
      end

      it "não pede senha nesse formulário" do
        start_and_callback
        follow_redirect!

        expect(response.body).not_to include(%(name="user[password]"))
      end

      # Sem saída, o formulário ficaria preso no modo do provedor até o
      # navegador fechar: o perfil pendente vive na sessão.
      it "deixa desistir e voltar ao cadastro com senha" do
        start_and_callback

        get signup_path(oauth: "cancelar")
        follow_redirect!

        expect(response.body).to include(%(name="user[password]"))
        expect(response.body).not_to include("piloto@gmail.com")
      end
    end

    describe "cadastro que veio do provedor" do
      let(:attributes) do
        { name: "Piloto de Trilha", phone: "(41) 98877-0011", city: "Curitiba", state: "PR" }
      end

      before do
        stub_google
        start_and_callback
      end

      it "cria a conta e o vínculo" do
        expect { post signup_path, params: { user: attributes } }
          .to change(User, :count).by(1).and change(OauthIdentity, :count).by(1)
      end

      it "já nasce confirmada, porque o provedor verificou o endereço" do
        post signup_path, params: { user: attributes }

        expect(User.last).to be_confirmed
      end

      it "não manda e-mail de confirmação" do
        expect { post signup_path, params: { user: attributes } }
          .not_to have_enqueued_mail(UserMailer, :confirmation)
      end

      it "já entra" do
        expect { post signup_path, params: { user: attributes } }.to change(Session, :count).by(1)
      end

      # O e-mail vem da sessão, não do POST: aceitar o do formulário deixaria
      # alguém entrar com o Google de um endereço e sair cadastrado, já
      # confirmado, com o endereço de outra pessoa.
      it "ignora o e-mail enviado no formulário" do
        post signup_path, params: { user: attributes.merge(email: "vitima@empresa.com.br") }

        expect(User.last.email).to eq("piloto@gmail.com")
      end

      it "não deixa o cadastro pendente valer duas vezes" do
        post signup_path, params: { user: attributes }
        delete logout_path

        expect { post signup_path, params: { user: attributes.merge(name: "Outro") } }
          .not_to change(User, :count)
      end
    end

    describe "quem já tem conta" do
      it "entra pelo vínculo" do
        identity = create(:oauth_identity, provider: "google", uid: "1078")
        stub_google

        expect { start_and_callback }.to change(Session, :count).by(1)
        expect(Session.last.user).to eq(identity.user)
      end

      # Quem se cadastrou com senha e agora prefere o Google: o vínculo é criado
      # na hora, porque o provedor verificou o mesmo endereço.
      it "liga o provedor a quem já existia com aquele e-mail" do
        user = create(:user, email: "piloto@gmail.com")
        stub_google

        expect { start_and_callback }.to change(user.oauth_identities, :count).by(1)
      end

      it "confirma de quebra quem ainda não tinha confirmado" do
        user = create(:user, :unconfirmed, email: "piloto@gmail.com")
        stub_google

        start_and_callback

        expect(user.reload).to be_confirmed
      end

      it "recusa anunciante bloqueado sem dizer por quê" do
        create(:oauth_identity, provider: "google", uid: "1078", user: create(:user, status: :blocked))
        stub_google

        expect { start_and_callback }.not_to change(Session, :count)
        expect(flash[:alert]).to eq(I18n.t("oauth.callback.failure"))
      end

      it "recusa quando a conta já está ligada a outro Google" do
        user = create(:user, email: "piloto@gmail.com")
        create(:oauth_identity, user: user, provider: "google", uid: "outro-uid")
        stub_google

        start_and_callback

        expect(flash[:alert]).to eq(I18n.t("oauth.callback.already_linked", provider: "Google"))
      end
    end

    describe "retorno que não presta" do
      before { stub_google }

      # Sem esta checagem, um retorno forjado logaria a vítima na conta de quem
      # atacou — o clássico login CSRF do OAuth.
      it "recusa state que não bate com o da sessão" do
        post oauth_authorization_path(provider: "google")

        get oauth_callback_path(provider: "google"), params: { code: "codigo", state: "forjado" }

        expect(response).to redirect_to(login_path)
        expect(flash[:alert]).to eq(I18n.t("oauth.callback.failure"))
      end

      it "recusa retorno sem state nenhum" do
        get oauth_callback_path(provider: "google"), params: { code: "codigo" }

        expect(flash[:alert]).to eq(I18n.t("oauth.callback.failure"))
      end

      # O state vale uma vez: reenviar o mesmo retorno não entra de novo.
      it "não aceita o mesmo state duas vezes" do
        post oauth_authorization_path(provider: "google")
        state = response.headers["Location"][/state=([^&]+)/, 1]
        params = { code: "codigo", state: state }

        get oauth_callback_path(provider: "google"), params: params
        expect { get oauth_callback_path(provider: "google"), params: params }.not_to change(User, :count)
      end

      it "trata a desistência de quem cancelou no provedor" do
        start_and_callback(error: "access_denied")

        expect(flash[:alert]).to eq(I18n.t("oauth.callback.denied"))
      end

      it "não entra quando o provedor não verificou o e-mail" do
        stub_google(profile_body: profile.merge(email_verified: false))

        expect { start_and_callback }.not_to change(Session, :count)
        expect(flash[:alert]).to eq(I18n.t("oauth.callback.failure"))
      end

      it "não entra quando a troca do código falha" do
        stub_google(token_status: 400)

        expect { start_and_callback }.not_to change(Session, :count)
      end
    end

    it "manda embora quem já está autenticado" do
      sign_in(create(:user))

      post oauth_authorization_path(provider: "google")

      expect(response).to redirect_to(root_path)
    end
  end
end
