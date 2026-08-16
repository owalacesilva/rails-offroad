class HomeController < ApplicationController
  allow_unauthenticated_access

  RECENT_LIMIT = 4

  def index
    published = Ad.published

    @categories = Category.ordered
    # Uma consulta agregada em vez de category.ads.count por card.
    @ad_counts = published.group(:category_id).count
    @ads = published.includes(:category, :ad_images).recent.limit(RECENT_LIMIT)
  end
end
