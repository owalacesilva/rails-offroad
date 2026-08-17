class ProposalsController < ApplicationController
  # Comprador manda proposta sem conta: o formulário já pede nome e e-mail.
  allow_unauthenticated_access

  def create
    @ad = Ad.published
            .with_photos.includes(:category, :user, technical_spec_values: :spec_attribute)
            .find(params[:ad_id])
    @proposal = @ad.proposals.new(proposal_params)
    # Quem já está logado fica ligado à proposta; anônimo segue com user_id nulo.
    @proposal.user = current_user if authenticated?

    if @proposal.save
      ProposalMailer.received(@proposal).deliver_later
      redirect_to ad_path(@ad), notice: t("proposals.create.success")
    else
      # Reabre a página do anúncio com o modal aberto e os erros no formulário.
      @related = @ad.related
      render "ads/show", status: :unprocessable_content
    end
  end

  private
    def proposal_params
      params.expect(proposal: [ :name, :email, :phone, :offered_value, :message ])
    end
end
