class AdsController < ApplicationController
  allow_unauthenticated_access

  def index
    @filter = AdFilter.new(filter_params)
    @pagination = Pagination.new(@filter.results, page: params[:page])
    @ads = @pagination.records
  end

  def show
    @ad = Ad.published
            .with_photos.includes(:category, :user, technical_spec_values: :spec_attribute)
            .find(params[:id])
    @related = @ad.related
    @proposal = @ad.proposals.new

    # Depois de carregar: o contador alimenta a régua "Mais Vistos" da home e
    # não pode custar uma consulta a mais na renderização desta página.
    @ad.record_view
  end

  private
    def filter_params
      params.permit(:q, :category, :state, :city, :sort)
    end
end
