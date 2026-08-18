require "rails_helper"

RSpec.describe "Imagem de destaque na gestão", type: :request do
  let(:admin) { create(:admin) }

  before { sign_in_admin(admin) }

  describe "POST /admin/uploads" do
    it "guarda a imagem e devolve o signed_id" do
      expect { post admin_uploads_path, params: { file: uploaded_png } }
        .to change(ActiveStorage::Blob, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(response.parsed_body["signed_id"]).to be_present
    end

    # Mesmos limites do upload de foto de anúncio: o concern é o mesmo.
    it "recusa imagem maior que o limite" do
      post admin_uploads_path, params: { file: uploaded_png(width: PhotoUpload::MAX_WIDTH + 1, height: 100) }

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "recusa arquivo que não é imagem" do
      post admin_uploads_path,
           params: { file: Rack::Test::UploadedFile.new(StringIO.new("nada"), "image/png", original_filename: "a.png") }

      expect(response.parsed_body["error"]).to eq(I18n.t("uploads.errors.unreadable"))
    end

    it "exige sessão de moderador" do
      delete admin_logout_path

      expect { post admin_uploads_path, params: { file: uploaded_png } }
        .not_to change(ActiveStorage::Blob, :count)
    end
  end

  describe "capa do evento" do
    let(:attributes) do
      { title: "Trilhão", starts_on: 10.days.from_now.to_date, city: "Curitiba", state: "PR" }
    end

    it "anexa a imagem enviada" do
      blob = photo_blob

      post admin_events_path, params: { event: attributes.merge(cover_signed_id: blob.signed_id) }

      expect(Event.last.cover_image).to be_attached
    end

    it "exibe o anexo em vez da URL" do
      blob = photo_blob

      post admin_events_path, params: { event: attributes.merge(cover_signed_id: blob.signed_id) }

      expect(Event.last.cover_url).to start_with("/rails/active_storage/blobs/proxy/")
    end

    # A coluna de URL continua valendo para imagem hospedada em outro lugar.
    it "cai na URL quando não há anexo" do
      post admin_events_path, params: { event: attributes.merge(image_url: "https://exemplo.com.br/capa.jpg") }

      expect(Event.last.cover_url).to eq("https://exemplo.com.br/capa.jpg")
    end

    # O formulário sempre manda os campos do evento junto; o params.expect da
    # controller recusa uma submissão que não traga nenhum deles.
    it "remove a capa quando o campo volta vazio" do
      event = create(:event)
      event.cover_image.attach(photo_blob)

      patch admin_event_path(event), params: { event: { title: event.title, cover_signed_id: "" } }

      expect(event.reload.cover_image).not_to be_attached
    end

    # Campo ausente significa "não mexi nisso": editar o título não pode apagar
    # a capa que já estava lá.
    it "preserva a capa quando o campo não vem no formulário" do
      event = create(:event)
      event.cover_image.attach(photo_blob)

      patch admin_event_path(event), params: { event: { title: "Outro nome" } }

      expect(event.reload.cover_image).to be_attached
    end

    it "ignora signed_id adulterado" do
      post admin_events_path, params: { event: attributes.merge(cover_signed_id: "nao-e-valido") }

      expect(Event.last.cover_image).not_to be_attached
    end
  end

  describe "capa do post" do
    let(:attributes) { { title: "Texto novo", body: "<p>Corpo.</p>" } }

    it "anexa a imagem enviada" do
      blob = photo_blob

      post admin_posts_path, params: { post: attributes.merge(cover_signed_id: blob.signed_id) }

      expect(Post.last.cover_image).to be_attached
    end

    it "exibe o anexo em vez da URL" do
      blob = photo_blob

      post admin_posts_path, params: { post: attributes.merge(cover_signed_id: blob.signed_id) }

      expect(Post.last.cover).to start_with("/rails/active_storage/blobs/proxy/")
    end
  end

  describe "formulários" do
    it "o de evento oferece o campo de capa" do
      get new_admin_event_path

      expect(response.body).to include(I18n.t("admin.cover.label"), 'data-controller="cover-upload"')
    end

    it "o de post oferece o campo de capa" do
      get new_admin_post_path

      expect(response.body).to include(I18n.t("admin.cover.label"), %(data-cover-upload-url-value="#{admin_uploads_path}"))
    end
  end
end
