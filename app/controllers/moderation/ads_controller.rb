module Moderation
  # Fila de moderação: a razão de existir do status e do admin_id em ads.
  #
  # Mesma tabela da gestão de anunciantes — filtro, ordenação, paginação e ação
  # em lote sobre as linhas marcadas —, com as fotos abertas na própria linha,
  # porque é olhando para elas que se aprova ou se rejeita.
  class AdsController < BaseController
    PER_PAGE = 20

    def index
      @filter = AdQueueFilter.new(filter_params)
      @counts = Ad.group(:status).count
      @pagination = Pagination.new(scoped_queue, page: params[:page], per_page: PER_PAGE)
      @ads = @pagination.records
    end

    def approve
      review(:approve) { |ad| ad.approve(current_admin) }
    end

    # Só a rejeição carrega recado: aprovar não precisa de explicação, e o
    # formulário da fila é quem cobra o texto de quem rejeita.
    def reject
      review(:reject) { |ad| ad.reject(current_admin, note: params[:note].presence) }
    end

    # As caixas de seleção da tabela. Um a um, e não update_all: aprovar passa
    # pela validação das 3 fotos, e quem não passa precisa ser contado à parte —
    # um UPDATE em massa publicaria anúncio incompleto.
    def bulk_review
      # O motivo é cobrado aqui e não no formulário: o campo mora dentro de um
      # <dialog>, e um `required` ali faria o Chrome recusar em silêncio o envio
      # do botão de aprovar, que compartilha o mesmo formulário.
      return redirect_back_to_queue(alert: t("admin.ads.bulk.note_required")) if reject_without_note?

      done, failed = bulk_outcome

      return redirect_back_to_queue(alert: t("admin.ads.bulk.none")) if done.zero? && failed.zero?

      redirect_back_to_queue(**bulk_message(done, failed))
    end

    private
      def scoped_queue
        @filter.results.with_all_photos.includes(:user, :category, :admin)
      end

      def filter_params
        params.permit(:q, :status, :category, :advertiser, :state, :min_price, :max_price, :sort, :dir)
      end

      def review(action)
        # Pela slug, e não pelo id: Ad#to_param devolve a slug, então é ela que
        # os helpers de rota colocam na URL, inclusive aqui na moderação.
        ad = Ad.find_by!(slug: params[:id])

        return redirect_back_to_queue(notice: t("admin.ads.#{action}.success", title: ad.title)) if yield(ad)

        # Aprovar sem as 3 fotos falha na validação; o moderador precisa saber.
        redirect_back_to_queue(alert: t("admin.ads.#{action}.failure",
                                        errors: ad.errors.full_messages.to_sentence))
      end

      def approving?
        params[:to] == "approve"
      end

      def reject_without_note?
        !approving? && params[:note].blank?
      end

      def bulk_outcome
        outcomes = Ad.where(id: params[:ad_ids]).map { |ad| apply_bulk_review(ad) }

        outcomes.partition(&:itself).map(&:size)
      end

      def apply_bulk_review(ad)
        return ad.approve(current_admin) if approving?

        ad.reject(current_admin, note: params[:note].presence)
      end

      def bulk_message(done, failed)
        action = approving? ? "approved" : "rejected"

        return { alert: t("admin.ads.bulk.failed", count: failed) } if done.zero?
        return { notice: t("admin.ads.bulk.#{action}", count: done) } if failed.zero?

        { alert: t("admin.ads.bulk.partial", count: done, failed: failed) }
      end

      # Volta para a fila como ela estava: aba, filtro, ordenação e página.
      #
      # A tela anterior mandava para a fila de destino ("aprovou, então vá para
      # os aprovados"), o que numa tabela tira o moderador do lugar a cada
      # clique: o anúncio some da aba onde estava, que é justamente o retorno
      # esperado de quem trabalha a fila de cima para baixo.
      def redirect_back_to_queue(flash_message)
        redirect_to admin_ads_path(params.fetch(:list, {}).permit!.to_h), **flash_message
      end
  end
end
