# Inscrição na newsletter pelo bloco da home. Visitante anônimo se inscreve:
# o formulário pede só o e-mail.
class NewsletterSubscriptionsController < ApplicationController
  allow_unauthenticated_access

  def create
    subscription = NewsletterSubscription.subscribe(params[:email], source: params[:source])

    if subscription&.persisted?
      redirect_to newsletter_anchor, notice: t("newsletter.create.success")
    else
      redirect_to newsletter_anchor, alert: t("newsletter.create.failure")
    end
  end

  private
    # Volta para onde o formulário estava e ancora no bloco: a home é longa e
    # sem a âncora o visitante cairia no topo sem ver o aviso.
    #
    # Destino fixo em vez de request.referer: o bloco só existe na home, e usar
    # o referer transformaria este redirect em redirecionamento aberto.
    def newsletter_anchor
      "#{root_path}#newsletter"
    end
end
