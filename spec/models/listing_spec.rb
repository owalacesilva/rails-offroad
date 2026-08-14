require "rails_helper"

RSpec.describe Listing, type: :model do
  subject { build(:listing) }

  it { is_expected.to belong_to(:category) }
  it { is_expected.to belong_to(:advertiser) }
  it { is_expected.to have_many(:proposals).dependent(:destroy) }
  it { is_expected.to have_many_attached(:photos) }
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

  describe "#ordered_specifications" do
    it "segue a ordem definida no model, não a que o jsonb devolve" do
      listing = create(:listing, specifications: { "color" => "Verde", "condition" => "Usado", "engine" => "3.6 V6" })

      expect(listing.reload.ordered_specifications.map(&:first)).to eq(%w[condition engine color])
    end

    it "joga chave fora da lista para o fim" do
      listing = create(:listing, specifications: { "chave_nova" => "x", "condition" => "Usado" })

      expect(listing.reload.ordered_specifications.map(&:first)).to eq(%w[condition chave_nova])
    end
  end

  describe "#related" do
    let(:vehicles) { create(:category, :vehicles) }
    let(:parts) { create(:category, :parts) }
    let(:listing) { create(:listing, category: vehicles, published_at: 1.hour.ago) }

    it "traz outro anúncio da mesma categoria" do
      sibling = create(:listing, category: vehicles)

      expect(listing.related).to contain_exactly(sibling)
    end

    it "não inclui o próprio anúncio" do
      create(:listing, category: vehicles)

      expect(listing.related).not_to include(listing)
    end

    it "ignora anúncio de outra categoria" do
      create(:listing, category: parts)

      expect(listing.related).to be_empty
    end

    it "respeita o limite" do
      create_list(:listing, 6, category: vehicles)

      expect(listing.related.size).to eq(described_class::RELATED_LIMIT)
    end

    it "ordena do mais recente para o mais antigo" do
      older = create(:listing, category: vehicles, published_at: 5.days.ago)
      newer = create(:listing, category: vehicles, published_at: 1.day.ago)

      expect(listing.related.to_a).to eq([ newer, older ])
    end
  end
end
