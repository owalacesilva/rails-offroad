require "vcr"

VCR.configure do |config|
  config.cassette_library_dir = Rails.root.join("spec/fixtures/vcr_cassettes").to_s
  config.hook_into :webmock

  # Permite marcar o exemplo com `:vcr` em vez de abrir um bloco use_cassette.
  config.configure_rspec_metadata!

  # Grava na primeira execução e reproduz depois.
  config.default_cassette_options = { record: :once }

  # Credenciais nunca entram nas cassetes versionadas.
  config.filter_sensitive_data("<MINIO_ROOT_USER>") { ENV.fetch("MINIO_ROOT_USER", nil) }
  config.filter_sensitive_data("<MINIO_ROOT_PASSWORD>") { ENV.fetch("MINIO_ROOT_PASSWORD", nil) }
  config.filter_sensitive_data("<DB_PASSWORD>") { ENV.fetch("DB_PASSWORD", nil) }
end
