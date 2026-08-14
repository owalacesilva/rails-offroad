require "rails_helper"
require "net/http"

# Garante que a política de rede está de pé: nenhum spec alcança a internet real.
RSpec.describe "Isolamento de HTTP na suíte" do
  # Com o VCR plugado no WebMock (hook_into :webmock), é o VCR que intercepta
  # primeiro — daí o erro ser UnhandledHTTPRequestError e não NetConnectNotAllowedError.
  it "bloqueia chamada externa não stubada" do
    expect { Net::HTTP.get(URI("https://example.com")) }
      .to raise_error(VCR::Errors::UnhandledHTTPRequestError)
  end

  it "libera a chamada quando ela está stubada" do
    stub_request(:get, "https://example.com").to_return(body: "trilha")

    expect(Net::HTTP.get(URI("https://example.com"))).to eq("trilha")
  end
end
