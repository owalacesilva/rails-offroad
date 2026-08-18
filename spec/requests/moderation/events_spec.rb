require "rails_helper"

RSpec.describe "Agenda de eventos", type: :request do
  let(:admin) { create(:admin) }

  let(:valid_attributes) do
    { title: "Trilhão da Serra", starts_on: 20.days.from_now.to_date, ends_on: 22.days.from_now.to_date,
      city: "Bom Jardim da Serra", state: "SC", venue: "Serra do Rio do Rastro",
      description: "Três dias de trilha.", url: "https://exemplo.com.br/trilhao" }
  end

  before { sign_in_admin(admin) }

  describe "GET /admin/eventos" do
    it "responde com sucesso" do
      get admin_events_path

      expect(response).to have_http_status(:ok)
    end

    it "não deixa nenhuma chave de tradução sem valor" do
      create(:event)

      get admin_events_path

      expect(response.body).not_to include("translation missing")
    end

    # A aba padrão é a que a home mostra.
    it "abre nos próximos eventos" do
      upcoming = create(:event, title: "Encontro que ainda vem")
      create(:event, :past, title: "Encontro que já foi")

      get admin_events_path

      expect(response.body).to include(upcoming.title)
      expect(response.body).not_to include("Encontro que já foi")
    end

    it "mostra o histórico quando pedido" do
      create(:event, title: "Encontro que ainda vem")
      past = create(:event, :past, title: "Encontro que já foi")

      get admin_events_path(scope: "past")

      expect(response.body).to include(past.title)
      expect(response.body).not_to include("Encontro que ainda vem")
    end

    it "cai nos próximos quando a aba pedida não existe" do
      upcoming = create(:event)

      get admin_events_path(scope: "inventada")

      expect(response.body).to include(upcoming.title)
    end

    it "conta os dois grupos nas abas" do
      create_list(:event, 2)
      create(:event, :past)

      get admin_events_path

      expect(response.body).to include(I18n.t("admin.events.scopes.upcoming"), I18n.t("admin.events.scopes.past"))
    end

    it "explica a agenda vazia" do
      get admin_events_path

      expect(response.body).to include(I18n.t("admin.events.index.empty.upcoming.title"))
    end
  end

  describe "POST /admin/eventos" do
    it "cria o evento" do
      expect { post admin_events_path, params: { event: valid_attributes } }.to change(Event, :count).by(1)
    end

    # Não há fila de aprovação: o que a equipe publica já vale.
    it "entra na agenda da home na hora" do
      post admin_events_path, params: { event: valid_attributes }

      expect(Event.upcoming.pluck(:title)).to include("Trilhão da Serra")
    end

    it "redireciona para a lista com aviso" do
      post admin_events_path, params: { event: valid_attributes }

      expect(response).to redirect_to(admin_events_path)
      expect(flash[:notice]).to include("Trilhão da Serra")
    end

    it "devolve o formulário com 422 quando falta título" do
      post admin_events_path, params: { event: valid_attributes.merge(title: "") }

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "recusa término anterior ao início" do
      attributes = valid_attributes.merge(starts_on: Date.current, ends_on: Date.current - 1.day)

      expect { post admin_events_path, params: { event: attributes } }.not_to change(Event, :count)
    end

    it "recusa URL que não é http" do
      attributes = valid_attributes.merge(url: "javascript:alert(1)")

      expect { post admin_events_path, params: { event: attributes } }.not_to change(Event, :count)
    end
  end

  describe "GET /admin/eventos/:id/editar" do
    it "traz o evento preenchido" do
      event = create(:event, title: "Encontro Nacional")

      get edit_admin_event_path(event)

      expect(response.body).to include(event.title)
    end
  end

  describe "PATCH /admin/eventos/:id" do
    let(:event) { create(:event, title: "Nome antigo") }

    it "atualiza o evento" do
      patch admin_event_path(event), params: { event: { title: "Nome novo" } }

      expect(event.reload.title).to eq("Nome novo")
    end

    it "redireciona para a lista com aviso" do
      patch admin_event_path(event), params: { event: { title: "Nome novo" } }

      expect(flash[:notice]).to include("Nome novo")
    end

    it "devolve o formulário com 422 quando algo falha" do
      patch admin_event_path(event), params: { event: { title: "" } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(event.reload.title).to eq("Nome antigo")
    end

    it "volta para a aba de onde veio" do
      patch admin_event_path(event, scope: "past"), params: { event: { title: "Nome novo" } }

      expect(response).to redirect_to(admin_events_path(scope: "past"))
    end
  end

  describe "DELETE /admin/eventos/:id" do
    it "apaga o evento" do
      event = create(:event)

      expect { delete admin_event_path(event) }.to change(Event, :count).by(-1)
    end

    it "avisa o que saiu da agenda" do
      event = create(:event, title: "Encontro cancelado")

      delete admin_event_path(event)

      expect(flash[:notice]).to include(event.title)
    end
  end

  # Mesmo desenho da fila de moderação: sessão de anunciante não serve aqui.
  describe "acesso" do
    it "exige sessão de moderador" do
      delete admin_logout_path

      get admin_events_path

      expect(response).to redirect_to(admin_login_path)
    end

    it "não aceita sessão de anunciante no lugar da de moderador" do
      delete admin_logout_path
      sign_in(create(:user))

      get admin_events_path

      expect(response).to redirect_to(admin_login_path)
    end

    it "não cria evento sem sessão de moderador" do
      delete admin_logout_path

      expect { post admin_events_path, params: { event: valid_attributes } }.not_to change(Event, :count)
    end
  end
end
