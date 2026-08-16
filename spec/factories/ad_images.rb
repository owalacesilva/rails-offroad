FactoryBot.define do
  factory :ad_image do
    ad
    sequence(:file_url) { |n| "/seed-images/teste-#{n}.png" }
    sequence(:sort_order) { |n| n }
  end
end
