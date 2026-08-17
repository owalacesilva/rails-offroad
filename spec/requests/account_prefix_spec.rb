require "rails_helper"

# O painel do anunciante mora sob /anunciante. Os helpers seguem account_*
# porque o código é inglês, então nenhum outro spec olha para o caminho de fato:
# sem este, trocar o prefixo de volta passaria despercebido.
RSpec.describe "Prefixo do painel do anunciante", type: :request do
  it "monta todas as rotas do painel sob /anunciante" do
    paths = [ account_path, account_ads_path, new_account_ad_path, edit_profile_path, proposals_path ]

    expect(paths).to all(start_with("/anunciante"))
  end

  it "não responde mais no prefixo antigo" do
    get "/minha-conta"

    expect(response).to have_http_status(:not_found)
  end

  it "continua exigindo login" do
    get account_path

    expect(response).to redirect_to(login_path)
  end
end
