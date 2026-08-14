FactoryBot.define do
  factory :session do
    advertiser { nil }
    user_agent { "MyString" }
    ip_address { "MyString" }
  end
end
