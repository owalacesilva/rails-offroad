require "rails_helper"

RSpec.describe Advertiser, type: :model do
  subject { build(:advertiser) }

  it { is_expected.to have_many(:listings).dependent(:restrict_with_error) }
  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_presence_of(:city) }
  it { is_expected.to validate_presence_of(:member_since) }
  it { is_expected.to validate_length_of(:state).is_equal_to(2) }
  it { is_expected.to validate_uniqueness_of(:email).case_insensitive }

  describe "telefone" do
    it "aceita dígitos com código do país" do
      expect(build(:advertiser, phone: "5541988770011")).to be_valid
    end

    it "recusa telefone formatado, que quebraria o link do wa.me" do
      expect(build(:advertiser, phone: "(41) 98877-0011")).not_to be_valid
    end

    it "recusa telefone sem código do país" do
      expect(build(:advertiser, phone: "988770011")).not_to be_valid
    end
  end

  describe "#location" do
    it "junta cidade e UF" do
      advertiser = build(:advertiser, city: "Cuiabá", state: "MT")

      expect(advertiser.location).to eq("Cuiabá, MT")
    end
  end
end
