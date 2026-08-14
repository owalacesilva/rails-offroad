require "rails_helper"

RSpec.describe Listing, type: :model do
  subject { build(:listing) }

  it { is_expected.to belong_to(:category) }
  it { is_expected.to validate_presence_of(:title) }
  it { is_expected.to validate_presence_of(:city) }
  it { is_expected.to validate_presence_of(:published_at) }
  it { is_expected.to validate_length_of(:state).is_equal_to(2) }
  it { is_expected.to validate_numericality_of(:price_cents).only_integer.is_greater_than(0) }

  it "nomeia o badge de novidade como new_arrival para não colidir com Listing.new" do
    expect(described_class.badges.keys).to contain_exactly("prepared", "featured", "new_arrival")
  end

  describe "#price" do
    it "converte centavos em reais" do
      expect(build(:listing, price_cents: 38_990_000).price).to eq(389_900)
    end

    it "preserva os centavos" do
      expect(build(:listing, price_cents: 879_050).price).to eq(8_790.5)
    end
  end

  describe "ano" do
    it "aceita anúncio sem ano" do
      expect(build(:listing, :without_year)).to be_valid
    end

    it "recusa ano no futuro distante" do
      expect(build(:listing, year: Date.current.year + 5)).not_to be_valid
    end
  end

  it "barra preço não positivo no próprio banco" do
    listing = build(:listing, price_cents: 0)

    expect { listing.save!(validate: false) }.to raise_error(ActiveRecord::StatementInvalid, /listings_price_cents_positive/)
  end

  describe "escopos" do
    let(:vehicles) { create(:category, :vehicles) }
    let(:parts) { create(:category, :parts) }

    it "by_category filtra pelo slug" do
      wrangler = create(:listing, category: vehicles)
      create(:listing, category: parts)

      expect(described_class.by_category("veiculos-4x4")).to eq([ wrangler ])
    end

    it "recent ordena da publicação mais nova para a mais antiga" do
      older = create(:listing, category: vehicles, published_at: 3.days.ago)
      newer = create(:listing, category: vehicles, published_at: 1.day.ago)

      expect(described_class.recent).to eq([ newer, older ])
    end
  end
end
