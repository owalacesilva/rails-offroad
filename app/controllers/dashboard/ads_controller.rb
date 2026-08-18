module Dashboard
  # "Meus Anúncios": com moderação, o anunciante precisa ver em que pé está cada
  # anúncio, não só quantos ele tem.
  class AdsController < BaseController
    AD_FIELDS = %i[title description price category_id year city state].freeze

    def index
      scope = current_user.ads.with_photos.includes(:category)

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
      build_specifications(@ad)

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

      # As fotos já subiram uma a uma pelo Dropzone (ver AdPhotosController) e
      # chegam aqui como signed_ids de blobs. A posição no array é a ordem da
      # fila no formulário, e é ela que vira o sort_order da galeria.
      def build_images(ad)
        submitted_blobs.each_with_index do |blob, index|
          ad.ad_images.build(sort_order: index).file.attach(blob)
        end
      end

      # find_signed devolve nil para id adulterado ou blob já removido, em vez
      # de estourar: a foto some da lista e quem reclama é a validação de 3 a 10.
      # O first(máximo) evita que um POST fora do formulário mande mil fotos.
      def submitted_blobs
        Array(params[:photo_signed_ids])
          .filter_map { |signed_id| ActiveStorage::Blob.find_signed(signed_id) }
          .first(Ad::IMAGE_COUNT.max)
      end

      # As especificações chegam como { attribute_id => valor }. O formulário
      # mostra as da categoria escolhida e pede todas; quem cobra de fato é a
      # validação do modelo no contexto :submission, porque o formulário pode
      # ser contornado.
      def build_specifications(ad)
        submitted_specifications.each do |attribute_id, value|
          next if value.blank?

          ad.technical_spec_values.build(attribute_id: attribute_id, value: value)
        end
      end

      # A lista branca são os ids de atributo que existem: permit! aceitaria
      # qualquer chave, e uma inventada só estouraria lá na chave estrangeira.
      #
      # O try cobre `specs` vindo como texto em vez de hash, que é o que um POST
      # montado à mão manda: String não responde a permit e a coisa vira {}.
      def submitted_specifications
        params[:specs].try(:permit, *SpecAttribute.ids.map(&:to_s))&.to_h || {}
      end

      def ad_params
        params.expect(ad: AD_FIELDS)
      end
  end
end
