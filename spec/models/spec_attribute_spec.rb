require "rails_helper"

RSpec.describe SpecAttribute, type: :model do
  subject { build(:spec_attribute) }

  it { is_expected.to have_many(:technical_spec_values).dependent(:destroy) }
  it { is_expected.to validate_presence_of(:name) }

  # A tabela se chama `attributes`; a constante não pode, por causa de
  # ActiveModel::Attribute.
  it "aponta para a tabela attributes" do
    expect(described_class.table_name).to eq("attributes")
  end

  it "recusa nome repetido" do
    create(:spec_attribute, name: "condition")

    expect(build(:spec_attribute, name: "condition")).not_to be_valid
  end

  described_class::DATA_TYPES.each do |data_type|
    it "aceita o tipo de dado #{data_type}" do
      expect(build(:spec_attribute, data_type: data_type)).to be_valid
    end
  end

  it "recusa tipo de dado fora da lista" do
    expect(build(:spec_attribute, data_type: "BOOLEAN")).not_to be_valid
  end

  it "barra tipo de dado desconhecido no próprio banco" do
    attribute = build(:spec_attribute, data_type: "BOOLEAN")

    expect { attribute.save!(validate: false) }
      .to raise_error(ActiveRecord::StatementInvalid, /attributes_data_type_valid/)
  end

  it "ordena pela posição" do
    second = create(:spec_attribute, position: 2)
    first = create(:spec_attribute, position: 1)

    expect(described_class.ordered).to eq([ first, second ])
  end

  it "traduz o rótulo pelo nome" do
    expect(create(:spec_attribute, :condition).label).to eq(I18n.t("ads.specifications.condition"))
  end

  it "cai no nome humanizado quando não há tradução" do
    expect(create(:spec_attribute, name: "torque_nm").label).to eq("Torque nm")
  end
end
