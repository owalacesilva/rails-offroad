class HomeController < ApplicationController
  allow_unauthenticated_access

  RECENT_LIMIT = 4

  def index
    @categories = Category.ordered
    # Uma consulta agregada em vez de category.listings.count por card.
    @listing_counts = Listing.group(:category_id).count
    @listings = Listing.includes(:category).recent.limit(RECENT_LIMIT)
  end
end
