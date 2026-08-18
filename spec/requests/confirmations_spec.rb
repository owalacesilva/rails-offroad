require "rails_helper"

RSpec.describe "Confirmação de e-mail", type: :request do
  let(:user) { create(:user, :unconfirmed, email: "novo@exemplo.com.br") }

  def token_for(record)
    record.generate_token_for(:email_confirmation)
  end

  describe "GET /confirmar/:token" do
    it "confirma a conta" do
      get email_confirmation_path(token_for(user))

      expect(user.reload).to be_confirmed
    end

    it "manda entrar" do
      get email_confirmation_path(token_for(user))

      expect(response).to redirect_to(login_path)
      expect(flash[:notice]).to eq(I18n.t("confirmations.show.success"))
    end

    # Cliente de e-mail que pré-carrega links abre o mesmo link duas vezes: a
    # segunda não pode virar erro na cara de quem já confirmou.
    it "aceita o mesmo link duas vezes" do
      token = token_for(user)
      get email_confirmation_path(token)
      get email_confirmation_path(token)

      expect(response).to redirect_to(login_path)
    end

    it "recusa token adulterado e oferece o reenvio" do
      get email_confirmation_path("nao-e-um-token")

      expect(response).to redirect_to(new_email_confirmation_path)
      expect(flash[:alert]).to eq(I18n.t("confirmations.show.invalid"))
    end

    it "recusa token vencido" do
      token = token_for(user)

      travel(User::CONFIRMATION_WINDOW + 1.hour) do
        get email_confirmation_path(token)

        expect(user.reload).not_to be_confirmed
      end
    end

    # Sem sessão automática: confirmar prova o endereço, não substitui a senha.
    it "não autentica ninguém" do
      expect { get email_confirmation_path(token_for(user)) }.not_to change(Session, :count)
    end
  end

  describe "GET /confirmar" do
    it "responde com sucesso" do
      get new_email_confirmation_path

      expect(response).to have_http_status(:ok)
    end

    it "não deixa nenhuma chave de tradução sem valor" do
      get new_email_confirmation_path

      expect(response.body).not_to include("translation missing")
    end

    # Vem do login de quem ainda não confirmou, que acabou de digitar o endereço.
    it "preenche o e-mail que veio na URL" do
      get new_email_confirmation_path(email: "novo@exemplo.com.br")

      expect(response.body).to include(%(value="novo@exemplo.com.br"))
    end
  end

  describe "POST /confirmar" do
    it "reenvia para quem ainda não confirmou" do
      user

      expect { post email_confirmations_path, params: { email: user.email } }
        .to have_enqueued_mail(UserMailer, :confirmation)
    end

    it "não reenvia para quem já confirmou" do
      confirmed = create(:user)

      expect { post email_confirmations_path, params: { email: confirmed.email } }
        .not_to have_enqueued_mail(UserMailer, :confirmation)
    end

    it "aceita o e-mail em outra caixa" do
      user

      expect { post email_confirmations_path, params: { email: "NOVO@EXEMPLO.COM.BR" } }
        .to have_enqueued_mail(UserMailer, :confirmation)
    end

    # A resposta é a mesma exista ou não a conta: o contrário faria do
    # formulário um verificador de quem é cadastrado no portal.
    it "responde igual para endereço que não existe" do
      user
      post email_confirmations_path, params: { email: "ninguem@exemplo.com.br" }
      resposta_desconhecido = [ response.status, flash[:notice] ]

      post email_confirmations_path, params: { email: user.email }

      expect([ response.status, flash[:notice] ]).to eq(resposta_desconhecido)
    end

    it "não envia nada para endereço que não existe" do
      expect { post email_confirmations_path, params: { email: "ninguem@exemplo.com.br" } }
        .not_to have_enqueued_mail(UserMailer, :confirmation)
    end
  end

  describe "login antes de confirmar" do
    it "recusa a entrada" do
      expect { sign_in(user) }.not_to change(Session, :count)
    end

    it "leva ao reenvio com o e-mail preenchido" do
      sign_in(user)

      expect(response).to redirect_to(new_email_confirmation_path(email: user.email))
      expect(flash[:alert]).to eq(I18n.t("sessions.create.unconfirmed"))
    end

    # Só depois da senha certa. Para quem errou a senha, a resposta continua
    # sendo a genérica, que não diz se o e-mail existe.
    it "não conta nada a quem errou a senha" do
      sign_in(user, password: "errada")

      expect(response.body).to include(I18n.t("sessions.create.failure"))
    end

    it "não conta nada sobre conta bloqueada" do
      blocked = create(:user, :unconfirmed, status: :blocked)

      sign_in(blocked)

      expect(response.body).to include(I18n.t("sessions.create.failure"))
    end
  end
end
