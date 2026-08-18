require "rails_helper"

RSpec.describe "Propostas Recebidas", type: :request do
  let(:user) { create(:user) }
  let(:ad) { create(:ad, user: user, title: "Jeep Wrangler de Teste") }

  before { sign_in(user) }

  describe "GET /anunciante/propostas" do
    let!(:proposal) do
      create(:proposal, ad: ad, name: "Eduardo Bastos", email: "eduardo@exemplo.com.br",
                        phone: "(41) 9 9876-5544", offered_value: "425.000,00",
                        message: "Pago à vista.")
    end

    before { get proposals_path }

    it "responde com sucesso" do
      expect(response).to have_http_status(:ok)
    end

    it "não deixa nenhuma chave de tradução sem valor" do
      expect(response.body).not_to include("translation missing")
    end

    it "lista a proposta recebida" do
      expect(response.body).to include(proposal.name)
    end

    it "não mostra proposta de anúncio de outro anunciante" do
      create(:proposal, ad: create(:ad), name: "Alheio Silva")

      get proposals_path

      expect(response.body).not_to include("Alheio Silva")
    end

    # O layout da lista não mudou: o botão abre um <dialog> com o detalhe.
    describe "ver detalhes" do
      it "traz o botão de ver detalhes" do
        expect(response.body).to include(I18n.t("dashboard.proposals_index.details"), 'data-action="modal#open"')
      end

      it "monta um modal por proposta" do
        expect(response.body).to include(%(aria-labelledby="proposal-#{proposal.id}-title"))
      end

      it "mostra o contato completo dentro do modal" do
        expect(response.body).to include(proposal.email, proposal.phone, proposal.message)
      end

      it "formata o valor em reais" do
        expect(response.body).to include(ERB::Util.html_escape("R$ 425.000,00"))
      end

      it "oferece responder por e-mail com o assunto pronto" do
        expect(response.body).to include(I18n.t("dashboard.proposals_index.reply"), "mailto:#{proposal.email}")
      end
    end
  end

  it "exige sessão" do
    delete logout_path
    get proposals_path

    expect(response).to redirect_to(login_path)
  end
end
