module Moderation
  # Fila de moderação: a razão de existir do status e do admin_id em ads.
  class AdsController < BaseController
    def index
      @status = requested_status
      @counts = Ad.group(:status).count
      @ads = Ad.where(status: @status)
               .with_all_photos.includes(:user, :category)
               .order(created_at: :desc)
    end

    def approve
      review(:approve) { |ad| ad.approve(current_admin) }
    end

    # Só a rejeição carrega recado: aprovar não precisa de explicação, e o
    # formulário da fila é quem cobra o texto de quem rejeita.
    def reject
      review(:reject) { |ad| ad.reject(current_admin, note: params[:note].presence) }
    end

    private
      # Status desconhecido na URL cai na fila padrão em vez de listar nada.
      def requested_status
        requested = params[:status]

        Ad::STATUSES.key?(requested&.to_sym) ? requested : Ad::STATUSES[:pending]
      end

      def review(action)
        # Pela slug, e não pelo id: Ad#to_param devolve a slug, então é ela que
        # os helpers de rota colocam na URL, inclusive aqui na moderação.
        ad = Ad.find_by!(slug: params[:id])
        reviewed = yield(ad)
        # Depois da avaliação o status mudou: a fila de destino é a nova.
        queue = admin_ads_path(status: ad.status)

        return redirect_to(queue, notice: t("admin.ads.#{action}.success", title: ad.title)) if reviewed

        # Aprovar sem as 3 fotos falha na validação; o moderador precisa saber.
        redirect_to queue, alert: t("admin.ads.#{action}.failure", errors: ad.errors.full_messages.to_sentence)
      end
  end
end
