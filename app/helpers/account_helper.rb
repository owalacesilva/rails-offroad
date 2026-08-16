module AccountHelper
  # A navegação lateral é renderizada pelo layout em toda página da conta, então
  # os contadores são memoizados: sem isto seriam duas consultas por página.
  def account_counts
    @account_counts ||= begin
      ads = current_user.ads

      { ads: ads.count, proposals: Proposal.where(ad: ads).count }
    end
  end

  # O item ativo ganha a barra lateral da marca; o resto fica neutro.
  NAV_STATE = {
    true => "border-brand-500 bg-brand-50 text-stone-900",
    false => "border-transparent text-stone-500 hover:bg-stone-50 hover:text-stone-900"
  }.freeze

  def account_nav_class(section, active)
    "flex items-center gap-3 border-l-4 px-5 py-3 text-sm font-semibold transition " \
      "#{NAV_STATE.fetch(section == active)}"
  end
end
