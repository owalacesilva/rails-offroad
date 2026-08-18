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

        redirect_to admin_ads_path(status: ad.reload.status),
                    notice: t("admin.images.block.success", title: ad.title)
      end

      # DELETE: desbloqueia. Devolver a foto ao ar é "apagar o bloqueio".
      def destroy
        ad = find_ad
        ad.ad_images.find(params[:id]).update!(blocked_at: nil)

        redirect_to admin_ads_path(status: ad.status),
                    notice: t("admin.images.unblock.success", title: ad.title)
      end

      private
        def find_ad
          Ad.with_all_photos.find_by!(slug: params[:ad_id])
        end
    end
  end
end
