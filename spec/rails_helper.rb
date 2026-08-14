# Carregado pelos specs que precisam do Rails inteiro (request, model, system).
require "spec_helper"
ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"

abort("The Rails environment is running in production mode!") if Rails.env.production?

require "rspec/rails"

# Configuração de factory_bot, shoulda-matchers, WebMock e VCR.
Rails.root.glob("spec/support/**/*.rb").sort_by(&:to_s).each { |file| require file }

# Garante que o schema do banco de teste está em dia antes de rodar a suíte.
begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  abort e.to_s.strip
end

RSpec.configure do |config|
  # Cada exemplo roda dentro de uma transação e sofre rollback ao final.
  config.use_transactional_fixtures = true

  config.filter_rails_from_backtrace!

  # Um exemplo que troca o locale não pode vazar para o próximo.
  config.before { I18n.locale = I18n.default_locale }
end
