require "rails_helper"

RSpec.describe UserMailer, type: :mailer do
  let(:user) { create(:user, :unconfirmed, name: "Garagem Trilha Livre", email: "contato@trilha.com.br") }
  let(:mail) { described_class.confirmation(user) }

  it "vai para o endereço do cadastro" do
    expect(mail.to).to eq([ "contato@trilha.com.br" ])
  end

  it "usa o remetente do portal" do
    expect(mail.from).to eq([ "nao-responda@offroadclassificados.com.br" ])
  end

  it "traz o assunto traduzido" do
    expect(mail.subject).to eq(I18n.t("user_mailer.confirmation.subject"))
  end

  it "chama a pessoa pelo nome" do
    expect(mail.body.encoded).to include("Garagem Trilha Livre")
  end

  # decoded e não encoded: o token é longo e o quoted-printable o quebra com "="
  # no fim da linha, o que corta o link no meio de qualquer regex.
  it "leva um link que confirma aquela conta" do
    token = mail.text_part.decoded[%r{/confirmar/(\S+)}, 1]

    expect(User.find_by_token_for(:email_confirmation, token)).to eq(user)
  end

  # Cliente que só mostra texto não renderiza o link: o endereço tem de estar à
  # vista nas duas partes.
  it "vai em HTML e em texto puro" do
    expect(mail.body.parts.map(&:mime_type)).to contain_exactly("text/plain", "text/html")
  end

  it "diz o prazo do link" do
    expect(mail.text_part.decoded).to include(I18n.t("user_mailer.confirmation.expires", hours: 48))
  end

  it "não deixa nenhuma chave de tradução sem valor" do
    expect(mail.body.encoded).not_to include("translation missing")
  end
end
