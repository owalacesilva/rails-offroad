require "rails_helper"

RSpec.describe SocialLinks do
  describe ".all" do
    it "monta um link por variável de ambiente preenchida" do
      links = described_class.all("SOCIAL_INSTAGRAM_URL" => "https://instagram.com/offroad")

      expect(links.map(&:key)).to eq([ :instagram ])
      expect(links.first.url).to eq("https://instagram.com/offroad")
      expect(links.first.label).to eq("Instagram")
    end

    # É o que evita o ícone que leva a "#": rede sem endereço some do rodapé.
    it "ignora variável ausente, vazia ou só com espaços" do
      links = described_class.all("SOCIAL_YOUTUBE_URL" => "", "SOCIAL_FACEBOOK_URL" => "   ")

      expect(links).to be_empty
    end

    it "segue a ordem declarada em NETWORKS, não a do ambiente" do
      links = described_class.all(
        "SOCIAL_WHATSAPP_URL" => "https://wa.me/5541900000000",
        "SOCIAL_INSTAGRAM_URL" => "https://instagram.com/offroad"
      )

      expect(links.map(&:key)).to eq([ :instagram, :whatsapp ])
    end

    it "não lê nada sem ambiente configurado" do
      expect(described_class.all({})).to be_empty
    end
  end
end
