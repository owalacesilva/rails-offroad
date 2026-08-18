module Moderation
  module Ads
    # Bloqueio e desbloqueio de uma foto avulsa do anúncio.
    #
    # É o meio-termo entre aprovar e rejeitar: uma imagem imprópria sai do ar
    # sem derrubar o anúncio inteiro. Se o bloqueio deixar o anúncio abaixo do
    # mínimo de fotos, Ad#block_image devolve ele para a fila com o recado.
    class ImagesController < BaseController
      # PATCH: bloqueia. O verbo é de atualização porque a foto continua
      # existindo — some do portal, não do banco.
      def update
        ad = find_ad
        image = ad.ad_images.find(params[:id])
        ad.block_image(image, current_admin, note: params[:note].presence)

        redirect_back_to_queue t("admin.images.blocked_notice", title: ad.title)
      end

      # DELETE: desbloqueia. Devolver a foto ao ar é "apagar o bloqueio".
      def destroy
        ad = find_ad
        ad.ad_images.find(params[:id]).update!(blocked_at: nil)

        redirect_back_to_queue t("admin.images.unblocked_notice", title: ad.title)
      end

      private
        def find_ad
          Ad.with_all_photos.find_by!(slug: params[:ad_id])
        end

        # Volta para a fila como ela estava — aba, filtro, ordenação e página —,
        # e com a linha do anúncio aberta, que é onde as fotos estão.
        def redirect_back_to_queue(notice)
          redirect_to admin_ads_path(params.fetch(:list, {}).permit!.to_h), notice: notice
        end
    end
  end
end
