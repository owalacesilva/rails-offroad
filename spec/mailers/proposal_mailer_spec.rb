require "rails_helper"

RSpec.describe ProposalMailer, type: :mailer do
  subject(:mail) { described_class.received(proposal) }

  let(:user) { create(:user, name: "Garagem Trilha Livre", email: "contato@trilhalivre.com.br") }
  let(:ad) { create(:ad, title: "Jeep Wrangler Rubicon", user: user) }
  let(:proposal) { create(:proposal, ad: ad, offered_value: 330_000, email: "comprador@exemplo.com.br") }

  it "vai para o anunciante" do
    expect(mail.to).to eq([ user.email ])
  end

  it "responde para quem fez a proposta" do
    expect(mail.reply_to).to eq([ proposal.email ])
  end

  it "põe o título do anúncio no assunto" do
    expect(mail.subject).to include(ad.title)
  end

  it "cumprimenta o anunciante pelo nome" do
    expect(mail.text_part.decoded).to include(user.name)
  end

  # Mailer não herda os helpers da aplicação como os controllers herdam.
  # Sem o `helper AdsHelper` no ApplicationMailer, isto estoura.
  it "formata o valor com o helper da aplicação" do
    expect(mail.text_part.decoded).to include("R$ 330.000")
  end

  it "leva o link do anúncio" do
    expect(mail.text_part.decoded).to include(ad.id.to_s)
  end

  it "manda também a versão HTML" do
    expect(mail.html_part.decoded).to include(ad.title)
  end
end
