require "rails_helper"

RSpec.describe "Cadastro", type: :request do
  let(:valid_attributes) do
    { name: "Oficina do Walace", email: "walace@oficina.com.br", phone: "(41) 98877-0011",
      city: "Curitiba", state: "PR", password: "segredo123", password_confirmation: "segredo123" }
  end

  def register(attributes)
    post signup_path, params: { user: attributes }
  end

  describe "GET /cadastrar" do
    it "responde com sucesso" do
      get signup_path

      expect(response).to have_http_status(:ok)
    end

    it "não deixa nenhuma chave de tradução sem valor" do
      get signup_path

      expect(response.body).not_to include("translation missing")
    end

    it "oferece as 27 unidades federativas" do
      get signup_path

      expect(response.body.scan(/<option value="[A-Z]{2}"/).size).to eq(User::BRAZILIAN_STATES.size)
    end
  end

  describe "com dados válidos" do
    it "cria o anunciante" do
      expect { register(valid_attributes) }.to change(User, :count).by(1)
    end

    it "normaliza o telefone digitado com formatação" do
      register(valid_attributes)

      expect(User.last.phone).to eq("5541988770011")
    end

    it "guarda o e-mail em minúsculas" do
      register(valid_attributes.merge(email: "WALACE@OFICINA.COM.BR"))

      expect(User.last.email).to eq("walace@oficina.com.br")
    end

    it "define member_since como hoje, sem depender do formulário" do
      register(valid_attributes)

      expect(User.last.member_since).to eq(Date.current)
    end

    it "já deixa a pessoa autenticada" do
      expect { register(valid_attributes) }.to change(Session, :count).by(1)
    end

    it "leva para a home" do
      register(valid_attributes)

      expect(response).to redirect_to(root_path)
    end
  end

  describe "com dados inválidos" do
    it "não cria nada quando a confirmação de senha não bate" do
      expect { register(valid_attributes.merge(password_confirmation: "outra")) }
        .not_to change(User, :count)
    end

    it "responde 422" do
      register(valid_attributes.merge(email: "nao-e-email"))

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "recusa UF fora da lista" do
      expect { register(valid_attributes.merge(state: "ZZ")) }.not_to change(User, :count)
    end

    it "recusa e-mail já cadastrado" do
      create(:user, email: "walace@oficina.com.br")

      expect { register(valid_attributes) }.not_to change(User, :count)
    end

    it "mostra os erros no formulário" do
      register(valid_attributes.merge(password_confirmation: "outra"))

      expect(response.body).to include(I18n.t("errors.messages.confirmation", attribute: User.human_attribute_name(:password)))
    end

    it "não autentica ninguém" do
      expect { register(valid_attributes.merge(email: "nao-e-email")) }.not_to change(Session, :count)
    end
  end
end
