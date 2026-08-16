module Dashboard
  class DashboardController < BaseController
    def index
      ads = current_user.ads

      @ads = ads.includes(:category)
      @proposals_count = Proposal.where(ad: ads).count
      @ads_by_category = ads.joins(:category).group("categories.slug").count
      # Com moderação, o anunciante precisa ver quantos estão parados na fila.
      @ads_by_status = ads.group(:status).count
      @categories = Category.ordered
    end
  end
end
