module Dashboard
  class ProposalsController < ApplicationController
    def index
      @proposals = Proposal.where(listing: current_advertiser.listings)
                            .includes(:listing)
                            .order(created_at: :desc)
    end
  end
end
