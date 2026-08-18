# travel / travel_to / freeze_time nos exemplos. Vêm do Active Support e não do
# rspec-rails, então precisam ser incluídos à mão — o projeto mocka com Mocha, e
# o que rspec-rails inclui sozinho é pouco.
RSpec.configure do |config|
  config.include ActiveSupport::Testing::TimeHelpers
end
