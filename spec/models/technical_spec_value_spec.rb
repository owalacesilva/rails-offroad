require "rails_helper"

RSpec.describe TechnicalSpecValue, type: :model do
  subject { build(:technical_spec_value) }

  it { is_expected.to belong_to(:ad) }
  it { is_expected.to belong_to(:spec_attribute) }
  it { is_expected.to validate_presence_of(:value) }

  it "usa chave primária composta" do
    expect(described_class.primary_key).to eq(%w[ad_id attribute_id])
  end

  it "não deixa o mesmo atributo repetir no mesmo anúncio" do
    ad = create(:ad)
    attribute = create(:spec_attribute)
    create(:technical_spec_value, ad: ad, spec_attribute: attribute, value: "Usado")

    duplicate = build(:technical_spec_value, ad: ad, spec_attribute: attribute, value: "Novo")

    expect { duplicate.save!(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
  end

  describe "#typed_value" do
    it "devolve texto quando o atributo é STRING" do
      value = create(:technical_spec_value, spec_attribute: create(:spec_attribute, data_type: "STRING"), value: "Usado")

      expect(value.typed_value).to eq("Usado")
    end

    it "devolve inteiro quando o atributo é INT" do
      value = create(:technical_spec_value, spec_attribute: create(:spec_attribute, data_type: "INT"), value: "48000")

      expect(value.typed_value).to eq(48_000)
    end

    it "devolve BigDecimal quando o atributo é DECIMAL" do
      value = create(:technical_spec_value, spec_attribute: create(:spec_attribute, data_type: "DECIMAL"), value: "3.6")

      expect(value.typed_value).to eq(BigDecimal("3.6"))
    end

    # Guardar é sempre texto livre: valor que não converte volta como veio, em
    # vez de virar zero silenciosamente.
    it "devolve o texto cru quando o valor não converte para o tipo declarado" do
      value = create(:technical_spec_value, spec_attribute: create(:spec_attribute, data_type: "INT"), value: "sob consulta")

      expect(value.typed_value).to eq("sob consulta")
    end
  end
end
