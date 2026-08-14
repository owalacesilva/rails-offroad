require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module OffroadClassifieds
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.eager_load_paths << Rails.root.join("extras")

    config.time_zone = "America/Sao_Paulo"

    # Localização: pt-BR é o padrão do portal, en-US disponível.
    # As traduções de Rails/Active Record vêm da gem rails-i18n.
    config.i18n.default_locale = :"pt-BR"
    config.i18n.available_locales = [ :"pt-BR", :"en-US" ]

    # Chave ausente em en-US cai para pt-BR em vez de estourar erro.
    config.i18n.fallbacks = true

    # Permite organizar as traduções em subpastas de config/locales.
    config.i18n.load_path += Dir[Rails.root.join("config/locales/**/*.{rb,yml}")]

    # RSpec no lugar do minitest; factories no lugar de fixtures.
    config.generators do |g|
      g.test_framework :rspec, fixture: false, view_specs: false, helper_specs: false, routing_specs: false
      g.factory_bot dir: "spec/factories"
    end
  end
end
