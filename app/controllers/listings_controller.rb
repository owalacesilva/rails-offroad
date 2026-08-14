class ListingsController < ApplicationController
  def index
    @filter = ListingFilter.new(filter_params)
    @pagination = Pagination.new(@filter.results, page: params[:page])
    @listings = @pagination.records
  end

  def show
    @listing = Listing.with_attached_photos.includes(:category, :advertiser).find(params[:id])
    @related = @listing.related
    @proposal = @listing.proposals.new
  end

  private
    def filter_params
      params.permit(:category, :state, :city, :sort)
    end
end
