require "webmock/rspec"

# Nenhuma chamada HTTP real sai da suíte: o que não estiver stubado levanta erro.
# localhost segue liberado por causa dos system specs (Capybara/Selenium).
WebMock.disable_net_connect!(allow_localhost: true)
