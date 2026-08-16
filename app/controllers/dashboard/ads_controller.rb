module Dashboard
  # "Meus Anúncios": com moderação, o anunciante precisa ver em que pé está cada
  # anúncio, não só quantos ele tem.
  class AdsController < BaseController
    def index
      scope = current_user.ads.includes(:category, :ad_images)

      @counts = scope.group(:status).count
      @status = requested_status
      @ads = (@status ? scope.where(status: @status) : scope).order(created_at: :desc)
    end

    private
      # Sem filtro na URL mostra tudo; status desconhecido também, em vez de
      # devolver lista vazia sem explicação.
      def requested_status
        requested = params[:status]

        requested if Ad::STATUSES.key?(requested&.to_sym)
      end
  end
end
