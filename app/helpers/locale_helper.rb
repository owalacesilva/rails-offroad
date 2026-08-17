# Tudo que a troca de idioma precisa nas views. O mecanismo em si já existe na
# ApplicationController (?locale= e default_url_options); aqui só se monta o
# link e os rótulos.
module LocaleHelper
  def offered_locales
    ApplicationController::SUPPORTED_LOCALES
  end

  def current_locale?(locale)
    locale.to_sym == I18n.locale
  end

  # "Português", "English" — nome próprio do idioma, nunca traduzido.
  def locale_name(locale)
    ApplicationController::LOCALE_NAMES.fetch(locale.to_s)
  end

  # "PT", "EN": a parte de idioma da tag, para o botão compacto do header.
  def locale_code(locale)
    locale.to_s.split("-").first.upcase
  end

  # Métodos cujo caminho pode virar link. HEAD entra junto de GET porque é
  # roteado igual — request.get? sozinho responderia false e mandaria para a
  # home uma página que tem, sim, endereço próprio.
  LINKABLE_METHODS = %w[GET HEAD].freeze

  # A página atual no outro idioma, preservando filtros e paginação.
  #
  # Montada a partir do caminho da requisição em vez de url_for porque a página
  # do anúncio também é renderizada em resposta a um POST (proposta inválida
  # recarrega ads/show), e regerar a rota daquele POST estouraria com
  # UrlGenerationError. Num caso desses o link volta para a home.
  def locale_switch_path(locale)
    query = request.query_parameters.except("locale")
    query["locale"] = locale.to_s unless default_locale?(locale)

    path = linkable_request? ? request.path : root_path
    query.empty? ? path : "#{path}?#{query.to_query}"
  end

  private
    # O locale padrão não vai na URL, igual ao default_url_options da controller.
    def default_locale?(locale)
      locale.to_sym == I18n.default_locale
    end

    def linkable_request?
      LINKABLE_METHODS.include?(request.request_method)
    end
end
