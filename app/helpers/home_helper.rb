module HomeHelper
  # Cores dos atalhos de busca do hero: veículo em escuro, peça em âmbar. A
  # distinção é o que deixa ler os dois grupos de relance.
  QUICK_SEARCH_STYLES = {
    vehicles: "bg-stone-800/80 text-stone-200 ring-stone-600/50 hover:bg-stone-700",
    parts: "bg-brand-500/20 text-brand-200 ring-brand-500/40 hover:bg-brand-500/30"
  }.freeze

  def quick_search_class(group)
    "rounded-full px-3 py-1.5 text-xs font-semibold ring-1 backdrop-blur transition " \
      "#{QUICK_SEARCH_STYLES.fetch(group)}"
  end

  # Categorias para o select do hero, no mesmo formato do painel de filtros.
  def home_category_options
    Category.ordered.map { |category| [ category.name, category.slug ] }
  end
end
