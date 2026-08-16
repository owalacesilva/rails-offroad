require "rails_helper"

RSpec.describe AdImage, type: :model do
  subject { build(:ad_image) }

  it { is_expected.to belong_to(:ad) }
  it { is_expected.to validate_presence_of(:file_url) }

  it "ordena pela coluna sort_order, que o Active Storage não tinha" do
    ad = create(:ad, image_count: 0, status: :pending)
    last = create(:ad_image, ad: ad, sort_order: 2)
    first = create(:ad_image, ad: ad, sort_order: 0)
    middle = create(:ad_image, ad: ad, sort_order: 1)

    expect(ad.ad_images.reload.to_a).to eq([ first, middle, last ])
  end

  it "recusa ordem negativa" do
    expect(build(:ad_image, sort_order: -1)).not_to be_valid
  end

  it "some junto com o anúncio" do
    ad = create(:ad)

    expect { ad.destroy }.to change(described_class, :count).by(-Ad::IMAGE_COUNT.min)
  end
end
