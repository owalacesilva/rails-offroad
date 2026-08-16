class ProposalMailer < ApplicationMailer
  def received(proposal)
    @proposal = proposal
    @ad = proposal.ad
    @user = @ad.user

    mail(
      to: @user.email,
      reply_to: proposal.email,
      subject: t("proposal_mailer.received.subject", title: @ad.title)
    )
  end
end
