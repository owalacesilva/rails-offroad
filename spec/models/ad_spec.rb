require "rails_helper"

RSpec.describe Ad, type: :model do
  subject { build(:ad) }

  it { is_expected.to belong_to(:category) }
  it { is_expected.to belong_to(:user) }
  it { is_expected.to belong_to(:admin).optional }
  it { is_expected.to have_many(:proposals).dependent(:destroy) }
  it { is_expected.to have_many(:ad_images).dependent(:destroy) }
  it { is_expected.to have_many(:technical_spec_values).dependent(:destroy) }
  it { is_expected.to validate_presence_of(:title) }
  it { is_expected.to validate_presence_of(:city) }
  it { is_expected.to validate_length_of(:state).is_equal_to(2) }
  it { is_expected.to validate_numericality_of(:price).is_greater_than(0) }

  it "nomeia o badge de novidade como new_arrival para não colidir com Ad.new" do
    expect(described_class.badges.keys).to contain_exactly("prepared", "featured", "new_arrival")
  end

  describe "#price" do
    it "guarda o valor em reais, sem conversão para centavos" do
      expect(build(:ad, price: 389_900).price).to eq(389_900)
    end

    it "preserva as duas casas decimais" do
      expect(create(:ad, price: 8_790.50).reload.price).to eq(8_790.50)
    end
  end

  describe "ano" do
    it "aceita anúncio sem ano" do
      expect(build(:ad, :without_year)).to be_valid
    end

    it "recusa ano no futuro distante" do
      expect(build(:ad, year: Date.current.year + 5)).not_to be_valid
    end
  end

  it "barra preço não positivo no próprio banco" do
    ad = build(:ad, price: 0)

    expect { ad.save!(validate: false) }.to raise_error(ActiveRecord::StatementInvalid, /ads_price_positive/)
  end

  describe "status" do
    it "nasce pendente quando não informado" do
      expect(described_class.new.status).to eq("pending")
    end

    it "barra status fora da lista no próprio banco" do
      ad = build(:ad)
      ad.save!

      expect { described_class.connection.execute("UPDATE ads SET status = 'inventado' WHERE id = '#{ad.id}'") }
        .to raise_error(ActiveRecord::StatementInvalid, /ads_status_valid/)
    end

    it "published traz só os aprovados" do
      approved = create(:ad)
      create(:ad, :pending)
      create(:ad, :rejected)

      expect(described_class.published).to eq([ approved ])
    end
  end

  describe "quantidade de fotos" do
    it "exige ao menos o mínimo em anúncio aprovado" do
      expect(build(:ad, image_count: described_class::IMAGE_COUNT.min - 1)).not_to be_valid
    end

    it "recusa mais que o máximo em anúncio aprovado" do
      expect(build(:ad, image_count: described_class::IMAGE_COUNT.max + 1)).not_to be_valid
    end

    it "não cobra fotos de rascunho" do
      expect(build(:ad, :draft)).to be_valid
    end
  end

  describe "#approve" do
    let(:admin) { create(:admin) }

    it "registra quem avaliou e publica" do
      ad = create(:ad, :pending, image_count: 3)

      expect(ad.approve(admin)).to be(true)
      expect(ad.reload).to have_attributes(status: "approved", admin: admin)
      expect(ad.published_at).to be_present
    end

    it "não aprova anúncio sem as fotos mínimas" do
      ad = create(:ad, :pending)

      expect(ad.approve(admin)).to be(false)
      expect(ad.reload.status).to eq("pending")
    end
  end

  describe "#reject" do
    it "registra quem avaliou sem publicar" do
      admin = create(:admin)
      ad = create(:ad, :pending)

      expect(ad.reject(admin)).to be(true)
      expect(ad.reload).to have_attributes(status: "rejected", admin: admin)
    end
  end

  describe "escopos" do
    let(:vehicles) { create(:category, :vehicles) }
    let(:parts) { create(:category, :parts) }

    it "by_category filtra pelo slug" do
      wrangler = create(:ad, category: vehicles)
      create(:ad, category: parts)

      expect(described_class.by_category("veiculos-4x4")).to eq([ wrangler ])
    end

    it "recent ordena da publicação mais nova para a mais antiga" do
      older = create(:ad, category: vehicles, published_at: 3.days.ago)
      newer = create(:ad, category: vehicles, published_at: 1.day.ago)

      expect(described_class.recent).to eq([ newer, older ])
    end
  end

  describe "#ordered_specifications" do
    let(:ad) { create(:ad) }

    def add_spec(name, value, position:, data_type: "STRING")
      attribute = create(:spec_attribute, name: name, position: position, data_type: data_type)
      create(:technical_spec_value, ad: ad, spec_attribute: attribute, value: value)
    end

    it "segue a coluna position do atributo, não a ordem de inserção" do
      add_spec("color", "Verde", position: 9)
      add_spec("condition", "Usado", position: 1)
      add_spec("engine", "3.6 V6", position: 3)

      expect(ad.reload.ordered_specifications.map(&:first)).to eq(%w[condition engine color])
    end

    it "converte o valor conforme o data_type do atributo" do
      add_spec("mileage_km", "48000", position: 2, data_type: "INT")

      expect(ad.reload.ordered_specifications).to eq([ [ "mileage_km", 48_000 ] ])
    end

    it "devolve vazio quando o anúncio não tem especificação" do
      expect(ad.ordered_specifications).to be_empty
    end
  end

  describe "#related" do
    let(:vehicles) { create(:category, :vehicles) }
    let(:parts) { create(:category, :parts) }
    let(:ad) { create(:ad, category: vehicles, published_at: 1.hour.ago) }

    it "traz outro anúncio da mesma categoria" do
      sibling = create(:ad, category: vehicles)

      expect(ad.related).to contain_exactly(sibling)
    end

    it "não inclui o próprio anúncio" do
      create(:ad, category: vehicles)

      expect(ad.related).not_to include(ad)
    end

    it "ignora anúncio de outra categoria" do
      create(:ad, category: parts)

      expect(ad.related).to be_empty
    end

    it "ignora anúncio que ainda não foi aprovado" do
      create(:ad, :pending, category: vehicles)

      expect(ad.related).to be_empty
    end

    it "respeita o limite" do
      create_list(:ad, 6, category: vehicles)

      expect(ad.related.size).to eq(described_class::RELATED_LIMIT)
    end

    it "ordena do mais recente para o mais antigo" do
      older = create(:ad, category: vehicles, published_at: 5.days.ago)
      newer = create(:ad, category: vehicles, published_at: 1.day.ago)

      expect(ad.related.to_a).to eq([ newer, older ])
    end
  end
end
