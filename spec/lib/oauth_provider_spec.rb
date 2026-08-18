require "rails_helper"

RSpec.describe OauthProvider do
  let(:env) do
    { "GOOGLE_CLIENT_ID" => "client-de-teste", "GOOGLE_CLIENT_SECRET" => "segredo" }
  end

  let(:google) { described_class.find(:google, env) }

  describe ".find" do
    it "monta o provedor quando o par de credenciais está no ambiente" do
      expect(google.key).to eq(:google)
      expect(google.label).to eq("Google")
    end

    it "aceita o nome como string, que é como vem da URL" do
      expect(described_class.find("google", env).key).to eq(:google)
    end

    # Sem o secret o portal não consegue trocar o código por um token: o
    # provedor pela metade é o mesmo que provedor nenhum.
    it "recusa par incompleto" do
      expect(described_class.find(:google, "GOOGLE_CLIENT_ID" => "só o id")).to be_nil
    end

    it "recusa credencial em branco" do
      expect(described_class.find(:google, env.merge("GOOGLE_CLIENT_SECRET" => "   "))).to be_nil
    end

    # Provedor desconhecido e provedor sem credencial devolvem a mesma coisa: de
    # fora, as duas situações são "essa rota não existe".
    it "devolve nil para provedor que o portal não conhece" do
      expect(described_class.find(:orkut, env)).to be_nil
    end
  end

  describe ".all" do
    it "lista só os configurados" do
      expect(described_class.all(env).map(&:key)).to eq([ :google ])
    end

    it "segue a ordem de PROVIDERS, não a do ambiente" do
      full = env.merge("FACEBOOK_APP_ID" => "1", "FACEBOOK_APP_SECRET" => "2")

      expect(described_class.all(full).map(&:key)).to eq([ :google, :facebook ])
    end

    it "não lista nada sem ambiente configurado" do
      expect(described_class.all({})).to be_empty
    end
  end

  describe "#authorize_url" do
    subject(:url) { google.authorize_url(state: "abc123", redirect_uri: "https://portal.test/retorno") }

    it "aponta para o provedor" do
      expect(url).to start_with("https://accounts.google.com/o/oauth2/v2/auth?")
    end

    it "leva o client_id, o escopo e o tipo de resposta" do
      expect(url).to include("client_id=client-de-teste", "scope=openid+email+profile", "response_type=code")
    end

    # O state volta na chamada de retorno e é o que prova que aquele retorno
    # pertence a esta sessão.
    it "leva o state e a URL de retorno" do
      expect(url).to include("state=abc123", "redirect_uri=https%3A%2F%2Fportal.test%2Fretorno")
    end

    it "não leva o secret" do
      expect(url).not_to include("segredo")
    end
  end

  describe "#profile" do
    def stub_token(body: { access_token: "token-de-acesso" }, status: 200)
      stub_request(:post, "https://oauth2.googleapis.com/token")
        .to_return(status: status, body: body.to_json, headers: { "Content-Type" => "application/json" })
    end

    def stub_userinfo(body:, status: 200)
      stub_request(:get, "https://openidconnect.googleapis.com/v1/userinfo")
        .to_return(status: status, body: body.to_json, headers: { "Content-Type" => "application/json" })
    end

    def profile
      google.profile(code: "codigo", redirect_uri: "https://portal.test/retorno")
    end

    it "troca o código por um perfil" do
      stub_token
      stub_userinfo(body: { sub: "1078", email: "Piloto@Gmail.com", email_verified: true, name: "Piloto" })

      expect(profile).to eq(
        OauthProfile.new(provider: "google", uid: "1078", email: "piloto@gmail.com", name: "Piloto")
      )
    end

    it "manda o secret e o código na troca" do
      stub_token
      stub_userinfo(body: { sub: "1", email: "a@b.com", email_verified: true, name: "A" })

      profile

      expect(WebMock).to have_requested(:post, "https://oauth2.googleapis.com/token")
        .with(body: hash_including("client_secret" => "segredo", "code" => "codigo",
                                   "grant_type" => "authorization_code", "redirect_uri" => "https://portal.test/retorno"))
    end

    it "consulta o perfil com o token que acabou de receber" do
      stub_token
      stub_userinfo(body: { sub: "1", email: "a@b.com", email_verified: true, name: "A" })

      profile

      expect(WebMock).to have_requested(:get, "https://openidconnect.googleapis.com/v1/userinfo")
        .with(headers: { "Authorization" => "Bearer token-de-acesso" })
    end

    # É o que impede alguém de abrir uma conta no provedor com o e-mail de outra
    # pessoa e entrar no lugar dela aqui.
    it "recusa e-mail que o provedor não verificou" do
      stub_token
      stub_userinfo(body: { sub: "1078", email: "piloto@gmail.com", email_verified: false, name: "Piloto" })

      expect(profile).to be_nil
    end

    # O Facebook não manda o campo: ele só devolve e-mail de conta já confirmada.
    it "aceita perfil sem o campo de verificação, que é o caso do Facebook" do
      facebook = described_class.find(:facebook, "FACEBOOK_APP_ID" => "1", "FACEBOOK_APP_SECRET" => "2")
      stub_request(:post, %r{graph\.facebook\.com/.+/oauth/access_token})
        .to_return(status: 200, body: { access_token: "t" }.to_json, headers: { "Content-Type" => "application/json" })
      stub_request(:get, %r{graph\.facebook\.com/.+/me})
        .to_return(status: 200, body: { id: "999", email: "piloto@facebook.com", name: "Piloto" }.to_json,
                   headers: { "Content-Type" => "application/json" })

      expect(facebook.profile(code: "c", redirect_uri: "https://portal.test/retorno").uid).to eq("999")
    end

    it "recusa perfil sem e-mail" do
      stub_token
      stub_userinfo(body: { sub: "1078", name: "Piloto" })

      expect(profile).to be_nil
    end

    # Falhar em silêncio é de propósito: a diferença entre código expirado,
    # provedor fora do ar e resposta estranha não é informação do visitante.
    it "devolve nil quando a troca do código falha" do
      stub_token(status: 400, body: { error: "invalid_grant" })

      expect(profile).to be_nil
    end

    it "devolve nil quando o provedor não devolve token" do
      stub_token(body: { token_type: "bearer" })

      expect(profile).to be_nil
    end

    it "devolve nil quando a consulta do perfil falha" do
      stub_token
      stub_userinfo(body: {}, status: 500)

      expect(profile).to be_nil
    end

    it "devolve nil quando o provedor está fora do ar" do
      stub_request(:post, "https://oauth2.googleapis.com/token").to_timeout

      expect(profile).to be_nil
    end

    it "devolve nil quando a resposta não é JSON" do
      stub_request(:post, "https://oauth2.googleapis.com/token")
        .to_return(status: 200, body: "<html>manutenção</html>")

      expect(profile).to be_nil
    end
  end
end
