require "rails_helper"

RSpec.describe Category, type: :model do
  subject { build(:category) }

  it { is_expected.to have_many(:ads).dependent(:restrict_with_error) }
  it { is_expected.to validate_presence_of(:slug) }
  it { is_expected.to validate_uniqueness_of(:slug) }
  it { is_expected.to validate_presence_of(:position) }

  describe "texto exibido" do
    let(:category) { build(:category, :vehicles) }

    it "busca o nome no locale a partir do slug" do
      expect(category.name).to eq("Veículos 4x4")
    end

    it "busca a descrição no locale a partir do slug" do
      expect(category.description).to eq(I18n.t("categories.veiculos-4x4.description"))
    end

    it "acompanha a troca de locale" do
      I18n.with_locale(:"en-US") do
        expect(category.name).to eq("4x4 Vehicles")
      end
    end
  end

  describe "#to_param" do
    it "usa o slug na URL, não o id" do
      expect(build(:category, :vehicles).to_param).to eq("veiculos-4x4")
    end
  end

  describe ".ordered" do
    it "ordena por position" do
      third = create(:category, position: 3)
      first = create(:category, position: 1)

      expect(described_class.ordered).to eq([ first, third ])
    end
  end
end
