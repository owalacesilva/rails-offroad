module AccountHelper
  # A navegação lateral é renderizada pelo layout em toda página da conta, então
  # os contadores são memoizados: sem isto seriam duas consultas por página.
  def account_counts
    @account_counts ||= begin
      ads = current_user.ads

      { ads: ads.count, proposals: Proposal.where(ad: ads).count }
    end
  end

  # Fotos que já subiram e precisam reaparecer quando a submissão volta com erro:
  # sem isto o anunciante subiria tudo de novo por causa de um preço inválido.
  # Blob que não existe mais some da lista em silêncio.
  def submitted_photos(signed_ids)
    Array(signed_ids).filter_map do |signed_id|
      blob = ActiveStorage::Blob.find_signed(signed_id)

      { signed_id: signed_id, url: rails_storage_proxy_path(blob), name: blob.filename.to_s } if blob
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
