require "rails_helper"

RSpec.describe Session, type: :model do
  it { is_expected.to belong_to(:user) }

  it "some junto com o anunciante" do
    user = create(:user)
    user.sessions.create!(user_agent: "rspec", ip_address: "127.0.0.1")

    expect { user.destroy }.to change(described_class, :count).by(-1)
  end
end
