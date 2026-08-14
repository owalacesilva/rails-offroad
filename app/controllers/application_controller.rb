class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  before_action :set_locale

  private
    # Precedência: ?locale= na URL, depois o Accept-Language do navegador,
    # senão o padrão da aplicação (pt-BR).
    def set_locale
      I18n.locale = locale_from_params || locale_from_header || I18n.default_locale
    end

    def locale_from_params
      supported_locale(params[:locale])
    end

    def locale_from_header
      request.env["HTTP_ACCEPT_LANGUAGE"].to_s
        .scan(/[a-z]{2}(?:-[a-z]{2})?/i)
        .lazy
        .filter_map { |tag| supported_locale(tag) }
        .first
    end

    # Comparação sem diferenciar caixa: o navegador pode mandar "en-us".
    def supported_locale(tag)
      return if tag.blank?

      I18n.available_locales.find { |locale| locale.to_s.casecmp?(tag.to_s) }
    end

    # Mantém o locale escolhido nos links gerados, menos quando é o padrão.
    def default_url_options
      locale = I18n.locale

      locale == I18n.default_locale ? {} : { locale: locale }
    end
end
