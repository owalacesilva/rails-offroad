class AdsController < ApplicationController
  allow_unauthenticated_access

  def index
    @filter = AdFilter.new(filter_params)
    @pagination = Pagination.new(@filter.results, page: params[:page])
    @ads = @pagination.records
  end

  def show
    @ad = Ad.published
            .includes(:category, :user, :ad_images, technical_spec_values: :spec_attribute)
            .find(params[:id])
    @related = @ad.related
    @proposal = @ad.proposals.new
  end

  private
    def filter_params
      params.permit(:q, :category, :state, :city, :sort)
    end
end
