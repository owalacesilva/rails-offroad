FactoryBot.define do
  factory :admin_session do
    admin
    user_agent { "RSpec" }
    ip_address { "127.0.0.1" }
  end
end
