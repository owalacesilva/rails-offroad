class ProposalMailer < ApplicationMailer
  def received(proposal)
    @proposal = proposal
    @listing = proposal.listing
    @advertiser = @listing.advertiser

    mail(
      to: @advertiser.email,
      reply_to: proposal.email,
      subject: t("proposal_mailer.received.subject", title: @listing.title)
    )
  end
end
