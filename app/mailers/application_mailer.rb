class ApplicationMailer < ActionMailer::Base
  default from: "OffRoad Classificados <nao-responda@offroadclassificados.com.br>"
  layout "mailer"

  # Mailer não herda os helpers da aplicação como os controllers herdam;
  # sem isto, ad_price não existe no template do e-mail.
  helper AdsHelper
end
