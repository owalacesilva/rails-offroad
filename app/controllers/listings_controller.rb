class ListingsController < ApplicationController
  def index
    @filter = ListingFilter.new(filter_params)
    @pagination = Pagination.new(@filter.results, page: params[:page])
    @listings = @pagination.records
  end

  private
    def filter_params
      params.permit(:category, :state, :city, :sort)
    end
end
