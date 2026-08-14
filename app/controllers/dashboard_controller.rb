class DashboardController < ApplicationController
  def index
    @listings = current_advertiser.listings.includes(:category)
    @proposals_count = Proposal.where(listing: @listings).count
    @listings_by_category = @listings.joins(:category).group("categories.slug").count
    @categories = Category.ordered
  end
end
