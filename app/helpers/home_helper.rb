module HomeHelper
  # Atalhos de busca do hero, em dois grupos como a vitrine sugere: primeiro o
  # que se compra inteiro, depois o que se compra para montar. São nomes de
  # modelo e de peça — nome próprio, por isso constante e não chave de tradução.
  #
  # Ficam no helper e não na controller: são dado de apresentação, e só a view
  # os consome.
  QUICK_SEARCHES = {
    vehicles: %w[Defender Wrangler Hilux Ranger Troller Jimny Bandeirante Frontier].freeze,
    parts: %w[Snorkel Guincho Suspensão Bloqueio Bagageiro Pneus].freeze
  }.freeze

  def quick_searches
    QUICK_SEARCHES
  end

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

  # Um ícone por seção da home. Mesmo traço dos ícones de categoria; ficam aqui
  # porque só a home os usa.
  SECTION_ICON_PATHS = {
    clock: [ "M12 6v6h4.5m4.5 0a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z" ],
    photo: [
      "m2.25 15.75 5.159-5.159a2.25 2.25 0 0 1 3.182 0l5.159 5.159m-1.5-1.5 1.409-1.409a2.25 2.25 0 0 1 3.182 0l2.909 2.909m-18 3.75h16.5a1.5 1.5 0 0 0 1.5-1.5V6a1.5 1.5 0 0 0-1.5-1.5H3.75A1.5 1.5 0 0 0 2.25 6v12a1.5 1.5 0 0 0 1.5 1.5Z"
    ],
    eye: [
      "M2.036 12.322a1.012 1.012 0 0 1 0-.639C3.423 7.51 7.36 4.5 12 4.5c4.638 0 8.573 3.007 9.963 7.178.07.207.07.431 0 .639C20.577 16.49 16.64 19.5 12 19.5c-4.638 0-8.573-3.007-9.963-7.178Z",
      "M15 12a3 3 0 1 1-6 0 3 3 0 0 1 6 0Z"
    ],
    calendar: [
      "M6.75 3v2.25M17.25 3v2.25M3 18.75V7.5a2.25 2.25 0 0 1 2.25-2.25h13.5A2.25 2.25 0 0 1 21 7.5v11.25m-18 0A2.25 2.25 0 0 0 5.25 21h13.5A2.25 2.25 0 0 0 21 18.75m-18 0v-7.5A2.25 2.25 0 0 1 5.25 9h13.5A2.25 2.25 0 0 1 21 11.25v7.5"
    ],
    document: [
      "M19.5 14.25v-2.625a3.375 3.375 0 0 0-3.375-3.375h-1.5A1.125 1.125 0 0 1 13.5 7.125v-1.5a3.375 3.375 0 0 0-3.375-3.375H8.25m2.25 0H5.625c-.621 0-1.125.504-1.125 1.125v17.25c0 .621.504 1.125 1.125 1.125h12.75c.621 0 1.125-.504 1.125-1.125V11.25a9 9 0 0 0-9-9Z",
      "M8.25 13.5h7.5M8.25 17.25h4.5"
    ],
    envelope: [
      "M21.75 6.75v10.5a2.25 2.25 0 0 1-2.25 2.25h-15a2.25 2.25 0 0 1-2.25-2.25V6.75m19.5 0A2.25 2.25 0 0 0 19.5 4.5h-15a2.25 2.25 0 0 0-2.25 2.25m19.5 0v.243a2.25 2.25 0 0 1-1.07 1.916l-7.5 4.615a2.25 2.25 0 0 1-2.36 0L3.32 8.91a2.25 2.25 0 0 1-1.07-1.916V6.75"
    ]
  }.freeze

  def home_section_icon(name, css_class: "h-5 w-5")
    outline_icon(SECTION_ICON_PATHS.fetch(name.to_sym), css_class: css_class, stroke_width: "2")
  end

  # Data do evento em uma linha. Um dia só sai por extenso ("12 de setembro");
  # vários saem no formato curto dos dois lados, que é o único jeito de a mesma
  # montagem servir para pt-BR ("12/09 a 14/09") e en-US ("Sep 12 – Sep 14") —
  # colapsar o mês repetido daria uma ordem de palavras diferente em cada idioma.
  def event_dates(event)
    starts_on = event.starts_on
    return l(starts_on, format: :event_day) if event.single_day?

    t("home.events.date_range",
      from: l(starts_on, format: :event_range_day),
      to: l(event.ends_on, format: :event_range_day))
  end
end
