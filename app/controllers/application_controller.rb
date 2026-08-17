class ApplicationController < ActionController::Base
  include Authentication

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  # Idiomas oferecidos ao usuário. Menor que I18n.available_locales de propósito:
  # :en existe só como base de fallback de en-US, não é escolhível.
  SUPPORTED_LOCALES = %w[pt-BR en-US].freeze

  # Cada idioma escrito no próprio idioma: "English" continua "English" com a
  # interface em português, e é por isso que fica aqui e não em config/locales —
  # não é texto traduzível, é o nome próprio do idioma. Fica junto da lista
  # acima de propósito: acrescentar um locale sem o nome quebra no fetch.
  LOCALE_NAMES = { "pt-BR" => "Português", "en-US" => "English" }.freeze

  before_action :set_locale

  private
    # O portal é brasileiro: pt-BR é o padrão e só sai dele por escolha explícita
    # em ?locale=. O Accept-Language do navegador não entra na conta de
    # propósito — ele diria "en-US" para qualquer visitante com o sistema em
    # inglês, e o padrão do portal deixaria de valer sem ninguém ter pedido.
    def set_locale
      I18n.locale = locale_from_params || I18n.default_locale
    end

    def locale_from_params
      supported_locale(params[:locale])
    end

    # Comparação sem diferenciar caixa: ?locale=en-us digitado à mão também vale.
    def supported_locale(tag)
      return if tag.blank?

      SUPPORTED_LOCALES.find { |locale| locale.casecmp?(tag.to_s) }&.to_sym
    end

    # Mantém o locale escolhido nos links gerados, menos quando é o padrão.
    def default_url_options
      locale = I18n.locale

      locale == I18n.default_locale ? {} : { locale: locale }
    end
end
