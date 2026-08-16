require "rails_helper"

RSpec.describe "Propostas", type: :request do
  let(:ad) { create(:ad, title: "Jeep Wrangler Rubicon") }
  let(:valid_attributes) do
    { name: "Walace Silva", email: "walace@exemplo.com.br", phone: "41999887766",
      offered_value: "350000", message: "Aceita troca?" }
  end

  def submit(attributes)
    post ad_proposals_path(ad), params: { proposal: attributes }
  end

  describe "com dados válidos" do
    it "grava a proposta" do
      expect { submit(valid_attributes) }.to change(Proposal, :count).by(1)
    end

    it "grava o valor em reais" do
      submit(valid_attributes)

      expect(Proposal.last.offered_value).to eq(350_000)
    end

    it "prende a proposta ao anúncio" do
      submit(valid_attributes)

      expect(Proposal.last.ad).to eq(ad)
    end

    it "volta para a página do anúncio" do
      submit(valid_attributes)

      expect(response).to redirect_to(ad_path(ad))
    end

    it "confirma o envio na tela" do
      submit(valid_attributes)
      follow_redirect!

      expect(response.body).to include(I18n.t("proposals.create.success"))
    end

    it "enfileira o e-mail para o anunciante" do
      expect { submit(valid_attributes) }
        .to have_enqueued_mail(ProposalMailer, :received)
    end
  end

  describe "com dados inválidos" do
    let(:invalid_attributes) { { name: "", email: "nao-e-email", amount: "0" } }

    it "não grava nada" do
      expect { submit(invalid_attributes) }.not_to change(Proposal, :count)
    end

    it "responde 422" do
      submit(invalid_attributes)

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "reabre o modal" do
      submit(invalid_attributes)

      expect(response.body).to include('data-modal-open-value="true"')
    end

    it "mostra os erros de validação" do
      submit(invalid_attributes)

      expect(response.body).to include(I18n.t("errors.messages.blank"))
    end

    it "não dispara e-mail" do
      expect { submit(invalid_attributes) }.not_to have_enqueued_mail(ProposalMailer, :received)
    end

    it "mantém a página do anúncio utilizável" do
      submit(invalid_attributes)

      expect(response.body).to include(ad.title)
    end
  end
end
