module Moderation
  # Gestão da agenda da home. Evento é conteúdo do portal, não de anunciante:
  # quem cria, edita e apaga é a moderação, e não há fila de aprovação — o que
  # a equipe publica já vale.
  class EventsController < BaseController
    include CoverAttachment

    EVENT_FIELDS = %i[title description starts_on ends_on city state venue url image_url featured].freeze

    # As duas listas da tela. "Próximos" é o que a home mostra; "Realizados"
    # existe para consultar e reaproveitar, não some do banco.
    SCOPES = %w[upcoming past].freeze

    def index
      @scope = requested_scope
      @events = Event.public_send(@scope)
      @counts = { "upcoming" => Event.upcoming.count, "past" => Event.past.count }
    end

    def new
      # A data de início já vem preenchida: é o campo que mais dá trabalho e
      # quase todo evento cadastrado é dos próximos meses.
      @event = Event.new(starts_on: Date.current)
    end

    def create
      @event = Event.new(event_params)

      return render :new, status: :unprocessable_content unless @event.save

      attach_cover(@event)

      redirect_to admin_events_path, notice: t("admin.events.create.success", title: @event.title)
    end

    def edit
      @event = find_event
    end

    def update
      @event = find_event

      return render :edit, status: :unprocessable_content unless @event.update(event_params)

      attach_cover(@event)

      redirect_to admin_events_path(scope: requested_scope),
                  notice: t("admin.events.update.success", title: @event.title)
    end

    def destroy
      event = find_event
      event.destroy

      redirect_to admin_events_path, notice: t("admin.events.destroy.success", title: event.title)
    end

    private
      def find_event
        Event.find(params[:id])
      end

      # Aba desconhecida na URL cai nos próximos, que é a lista útil.
      def requested_scope
        requested = params[:scope]

        SCOPES.include?(requested) ? requested : SCOPES.first
      end

      def event_params
        params.expect(event: EVENT_FIELDS)
      end
  end
end
