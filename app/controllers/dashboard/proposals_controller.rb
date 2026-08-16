module Dashboard
  class ProposalsController < BaseController
    def index
      @proposals = Proposal.where(ad: current_user.ads)
                            .includes(:ad)
                            .order(created_at: :desc)
    end
  end
end
