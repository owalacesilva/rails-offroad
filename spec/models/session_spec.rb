require "rails_helper"

RSpec.describe Session, type: :model do
  it { is_expected.to belong_to(:advertiser) }

  it "some junto com o anunciante" do
    advertiser = create(:advertiser)
    advertiser.sessions.create!(user_agent: "rspec", ip_address: "127.0.0.1")

    expect { advertiser.destroy }.to change(described_class, :count).by(-1)
  end
end
