module CategoriesHelper
  # Traços dos ícones de categoria, renderizados inline para não depender de assets externos.
  CATEGORY_ICON_PATHS = {
    truck: [
      "M8.25 18.75a1.5 1.5 0 0 1-3 0m3 0a1.5 1.5 0 0 0-3 0m3 0h6m-9 0H3.375a1.125 1.125 0 0 1-1.125-1.125V14.25m17.25 4.5a1.5 1.5 0 0 1-3 0m3 0a1.5 1.5 0 0 0-3 0m3 0h1.125c.621 0 1.129-.504 1.09-1.124a17.902 17.902 0 0 0-3.213-9.193 2.056 2.056 0 0 0-1.58-.86H14.25M16.5 18.75h-2.25m0-11.177v-.958c0-.568-.422-1.048-.987-1.106a48.554 48.554 0 0 0-10.026 0 1.106 1.106 0 0 0-.987 1.106v7.635m12-6.677v6.677m0 4.5v-4.5m0 0h-12"
    ],
    bike: [
      "M5.5 20.5a3.5 3.5 0 1 0 0-7 3.5 3.5 0 0 0 0 7Z",
      "M18.5 20.5a3.5 3.5 0 1 0 0-7 3.5 3.5 0 0 0 0 7Z",
      "M5.5 17h4l4-6h3l2.5 6M13.5 11 12 8H9.75M16.5 8h3.75"
    ],
    wrench: [
      "M21.75 6.75a4.5 4.5 0 0 1-4.884 4.484c-1.076-.091-2.264.071-2.95.904l-7.152 8.684a2.548 2.548 0 1 1-3.586-3.586l8.684-7.152c.833-.686.995-1.874.904-2.95a4.5 4.5 0 0 1 6.336-4.486l-3.276 3.276a3.004 3.004 0 0 0 2.25 2.25l3.276-3.276c.256.565.398 1.192.398 1.852Z"
    ]
  }.freeze

  # Slug da categoria -> ícone. Categoria sem ícone próprio cai no genérico.
  CATEGORY_ICONS = {
    "veiculos-4x4" => :truck,
    "motos-quadriciclos" => :bike,
    "utvs" => :truck,
    "pecas-acessorios" => :wrench
  }.freeze

  def category_icon(name, css_class: "h-6 w-6")
    paths = CATEGORY_ICON_PATHS.fetch(name.to_sym)

    tag.svg(
      safe_join(paths.map { |path_data| tag.path(d: path_data, "stroke-linecap": "round", "stroke-linejoin": "round") }),
      class: css_class,
      fill: "none",
      viewBox: "0 0 24 24",
      "stroke-width": "1.5",
      stroke: "currentColor",
      "aria-hidden": "true"
    )
  end

  def category_icon_for(slug, css_class: "h-6 w-6")
    category_icon(CATEGORY_ICONS.fetch(slug, :wrench), css_class: css_class)
  end
end
