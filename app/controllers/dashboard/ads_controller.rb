module Dashboard
  # "Meus Anúncios": com moderação, o anunciante precisa ver em que pé está cada
  # anúncio, não só quantos ele tem.
  class AdsController < BaseController
    AD_FIELDS = %i[title description price category_id year city state].freeze

    def index
      scope = current_user.ads.includes(:category, :ad_images)

      @counts = scope.group(:status).count
      @status = requested_status
      @ads = (@status ? scope.where(status: @status) : scope).order(created_at: :desc)
    end

    def new
      # Cidade e estado do cadastro: é de onde sai quase todo anúncio.
      @ad = current_user.ads.new(city: current_user.city, state: current_user.state)
    end

    def create
      @ad = current_user.ads.new(ad_params)
      # Quem publica é a moderação, não o anunciante: nasce na fila.
      @ad.status = :pending
      build_images(@ad)

      # O contexto :submission é o que cobra as 3 a 10 fotos já na criação.
      return render :new, status: :unprocessable_content unless @ad.save(context: :submission)

      redirect_to account_ads_path, notice: t("dashboard.ads.create.success", title: @ad.title)
    end

    private
      # Sem filtro na URL mostra tudo; status desconhecido também, em vez de
      # devolver lista vazia sem explicação.
      def requested_status
        requested = params[:status]

        requested if Ad::STATUSES.key?(requested&.to_sym)
      end

      # Uma URL por linha no formulário. A ordem das linhas vira o sort_order,
      # que é como ad_images guarda a ordem das fotos — o mesmo motivo de a
      # tabela existir no lugar do Active Storage.
      def build_images(ad)
        submitted_photo_urls.each_with_index do |url, index|
          ad.ad_images.build(file_url: url, sort_order: index)
        end
      end

      def submitted_photo_urls
        params[:photo_urls].to_s.split("\n").map(&:strip).reject(&:blank?)
      end

      def ad_params
        params.expect(ad: AD_FIELDS)
      end
  end
end
