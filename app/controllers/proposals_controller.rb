class ProposalsController < ApplicationController
  def create
    @listing = Listing.with_attached_photos.includes(:category, :advertiser).find(params[:listing_id])
    @proposal = @listing.proposals.new(proposal_params)

    if @proposal.save
      ProposalMailer.received(@proposal).deliver_later
      redirect_to listing_path(@listing), notice: t("proposals.create.success")
    else
      # Reabre a página do anúncio com o modal aberto e os erros no formulário.
      @related = @listing.related
      render "listings/show", status: :unprocessable_content
    end
  end

  private
    def proposal_params
      params.expect(proposal: [ :name, :email, :phone, :amount, :message ])
    end
end
