require "rails_helper"

RSpec.describe "Rodapé", type: :request do
  describe "redes sociais" do
    it "mostra um ícone por rede configurada no ambiente" do
      SocialLinks.stubs(:all).returns(
        [ SocialLinks::Link.new(key: :instagram, label: "Instagram", url: "https://instagram.com/offroad") ]
      )

      get root_path

      expect(response.body).to include("https://instagram.com/offroad", 'aria-label="Instagram"')
    end

    # É o que substitui os antigos links para "#": rede sem endereço some.
    it "esconde a faixa inteira quando nada está configurado" do
      SocialLinks.stubs(:all).returns([])

      get root_path

      expect(response.body).not_to include('aria-label="Instagram"')
    end
  end

  describe "links institucionais" do
    before { get root_path }

    it "leva às cinco páginas institucionais" do
      expect(response.body).to include(about_path, how_to_advertise_path, pricing_path,
                                       terms_of_use_path, privacy_policy_path)
    end

    it "transforma e-mail e telefone de contato em links de verdade" do
      expect(response.body).to include("mailto:#{I18n.t('layout.footer.contact.email')}", "tel:+55")
    end
  end
end
