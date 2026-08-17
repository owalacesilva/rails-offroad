require "rails_helper"

RSpec.describe "Autocomplete de municípios", type: :request do
  before do
    create(:city, :curitiba)
    create(:city, name: "Curiúva", state: "PR", ibge_code: "4106506")
    create(:city, name: "Cascavel", state: "PR", ibge_code: "4104808")
    create(:city, :sao_paulo)
  end

  def names(params)
    get cities_path(params)
    response.parsed_body
  end

  it "responde sem exigir login" do
    get cities_path(state: "PR")

    expect(response).to have_http_status(:ok)
  end

  it "devolve só os municípios da UF pedida" do
    expect(names(state: "PR")).to contain_exactly("Cascavel", "Curitiba", "Curiúva")
  end

  it "filtra pelo começo do nome" do
    expect(names(state: "PR", q: "curi")).to contain_exactly("Curitiba", "Curiúva")
  end

  # A collation do MySQL ignora acento e caixa, então o campo não precisa de
  # nenhuma coluna normalizada para "curiuva" achar "Curiúva".
  it "ignora acento e caixa na busca" do
    expect(names(state: "PR", q: "CURIUVA")).to eq([ "Curiúva" ])
  end

  it "ordena alfabeticamente" do
    expect(names(state: "PR")).to eq([ "Cascavel", "Curitiba", "Curiúva" ])
  end

  it "aceita a UF em minúsculas" do
    expect(names(state: "pr", q: "cas")).to eq([ "Cascavel" ])
  end

  # UF vazia é o estado inicial do formulário, não erro do usuário.
  it "devolve lista vazia sem UF" do
    expect(names(q: "curi")).to be_empty
  end

  it "devolve lista vazia para UF inexistente" do
    expect(names(state: "ZZ")).to be_empty
  end

  it "não devolve o acervo inteiro de uma vez" do
    expect(CitiesController::LIMIT).to be <= 25
  end

  it "corta no limite" do
    create_list(:city, CitiesController::LIMIT + 5, state: "SC")

    expect(names(state: "SC").size).to eq(CitiesController::LIMIT)
  end
end
