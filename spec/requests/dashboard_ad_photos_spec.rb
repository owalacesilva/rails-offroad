require "rails_helper"

RSpec.describe "Upload de foto do anúncio", type: :request do
  let(:user) { create(:user) }
  # Os limites são do concern compartilhado com o upload de capa da gestão.
  let(:limits) { PhotoUpload }

  before { sign_in(user) }

  def upload(file)
    post account_ad_photos_path, params: { file: file }
  end

  describe "POST /anunciante/anuncios/fotos" do
    it "guarda a foto e devolve o signed_id do blob" do
      expect { upload(uploaded_png) }.to change(ActiveStorage::Blob, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(response.parsed_body["signed_id"]).to be_present
    end

    # A URL é de proxy pelo mesmo motivo de AdImage#url: o endpoint do MinIO só
    # existe dentro da rede do Compose.
    it "devolve a URL de proxy para a miniatura" do
      upload(uploaded_png)

      expect(response.parsed_body["url"]).to start_with("/rails/active_storage/blobs/proxy/")
    end

    it "o signed_id devolvido vira um blob de verdade" do
      upload(uploaded_png)

      expect(ActiveStorage::Blob.find_signed(response.parsed_body["signed_id"])).to be_present
    end
  end

  # O Dropzone reduz a imagem antes de enviar, mas nada que vem do navegador
  # vale como garantia: quem impõe os limites é o servidor.
  describe "limites" do
    it "aceita imagem dentro do limite de dimensões" do
      upload(uploaded_png(width: limits::MAX_WIDTH, height: limits::MAX_HEIGHT))

      expect(response).to have_http_status(:created)
    end

    it "recusa imagem mais larga que o limite" do
      expect { upload(uploaded_png(width: limits::MAX_WIDTH + 1, height: 100)) }
        .not_to change(ActiveStorage::Blob, :count)

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "recusa imagem mais alta que o limite" do
      upload(uploaded_png(width: 100, height: limits::MAX_HEIGHT + 1))

      expect(response.parsed_body["error"]).to eq(
        I18n.t("uploads.errors.dimensions", width: limits::MAX_WIDTH, height: limits::MAX_HEIGHT)
      )
    end

    it "recusa arquivo de tipo não aceito" do
      upload(Rack::Test::UploadedFile.new(StringIO.new("nao sou imagem"), "application/pdf", original_filename: "a.pdf"))

      expect(response.parsed_body["error"]).to eq(I18n.t("uploads.errors.type"))
    end

    # Content-Type é o que o navegador diz, não o que o arquivo é.
    it "recusa arquivo que se diz imagem mas não abre" do
      upload(Rack::Test::UploadedFile.new(StringIO.new("PNG de mentira"), "image/png", original_filename: "a.png"))

      expect(response.parsed_body["error"]).to eq(I18n.t("uploads.errors.unreadable"))
    end

    it "recusa requisição sem arquivo" do
      post account_ad_photos_path

      expect(response.parsed_body["error"]).to eq(I18n.t("uploads.errors.missing"))
    end
  end

  it "exige sessão de anunciante" do
    delete logout_path
    upload(uploaded_png)

    expect(response).to redirect_to(login_path)
  end
end
