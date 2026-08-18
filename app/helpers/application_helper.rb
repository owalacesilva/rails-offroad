module ApplicationHelper
  DROPDOWN_ITEM = "flex w-full items-center gap-3 px-4 py-2.5 text-left text-sm " \
                  "font-semibold text-stone-600 transition hover:bg-stone-50 hover:text-stone-900".freeze

  # Item do menu de shared/_dropdown.
  def dropdown_item_class
    DROPDOWN_ITEM
  end

  # O filete que abre um bloco novo dentro do menu: é o que separa navegar de
  # sair. Vive sozinho porque dropdown_link já traz a classe do item e só
  # precisa do acréscimo.
  def dropdown_separator_class
    "mt-1 border-t border-stone-200 pt-3"
  end

  # O item e o filete juntos, para quem monta o link na mão.
  def separated_dropdown_item_class
    "#{DROPDOWN_ITEM} #{dropdown_separator_class}"
  end

  # Item da navegação central do header.
  def nav_link_class
    "inline-flex items-center gap-2 rounded-full px-3 py-2 text-sm font-semibold " \
      "text-stone-700 transition hover:bg-stone-100 hover:text-brand-600"
  end

  # Páginas institucionais do rodapé, na ordem em que aparecem: sufixo da chave
  # de tradução -> caminho. Fica no helper e não na view porque o rodapé da
  # área do anunciante mostra um recorte da mesma lista.
  def institutional_links
    {
      about: about_path,
      how_to_advertise: how_to_advertise_path,
      terms: terms_of_use_path,
      privacy: privacy_policy_path
    }
  end

  # "(41) 4002-8922" -> "tel:+554140028922". O href de tel: só aceita dígitos,
  # e o portal é brasileiro: o 55 é fixo.
  def tel_url(phone)
    "tel:+55#{phone.gsub(/\D/, '')}"
  end

  # Texto rico já limpo, pronto para a página. Duas origens convivem: o HTML do
  # editor e o texto puro com linhas em branco (o que o seed grava e o que sobra
  # de quem escreve com o JavaScript desligado).
  #
  # Distinguir os dois é direto depois de sanitizar: o sanitizador escapa
  # qualquer "<" que seja texto, então um "<" que sobrou é necessariamente tag.
  # Texto puro segue pelo simple_format, que transforma linha em branco em
  # parágrafo; sanitize: false porque a limpeza já aconteceu e escapar de novo
  # viraria "&amp;amp;".
  def rich_text(value)
    html = sanitize(value.to_s, tags: ApplicationRecord::RICH_TEXT_TAGS, attributes: [])
    return if html.blank?

    html.include?("<") ? html : simple_format(html, {}, sanitize: false)
  end

  # Quantas páginas aparecem de cada lado da atual quando a régua é longa.
  PAGE_WINDOW = 1

  # Os números da régua de paginação, com :gap onde há salto.
  #
  # Até sete páginas saem todas. Acima disso saem a primeira, a última, a atual
  # e as vizinhas — o resto vira reticências. É o que mantém a régua legível num
  # acervo com dezenas de páginas sem esconder para onde dá para ir.
  #
  #   1 … 4 5 [6] 7 8 … 20
  def paginated_page_numbers(pagination, window: PAGE_WINDOW)
    total = pagination.total_pages
    return (1..total).to_a if total <= (window * 2) + 5

    with_gaps(visible_pages(pagination.page, total, window))
  end

  private
    # Sempre a primeira, a última e a janela em torno da atual.
    def visible_pages(current, total, window)
      ([ 1, total ] + ((current - window)..(current + window)).to_a)
        .select { |page| page.between?(1, total) }
        .uniq
        .sort
    end

    # Onde a sequência salta um número, entra o :gap que a view desenha como "…".
    def with_gaps(pages)
      pages.each_cons(2).flat_map { |before, after| after - before > 1 ? [ before, :gap ] : [ before ] } + [ pages.last ]
    end

  public

  # Ícone de traço montado inline a partir dos seus paths. Os ícones do portal
  # são poucos e conhecidos em tempo de escrita: inline evita um sprite, uma
  # requisição e a dependência de um pacote de ícones. `currentColor` deixa a
  # cor com a classe do elemento, como em qualquer outro texto.
  def outline_icon(paths, css_class: "h-6 w-6", stroke_width: "1.5")
    tag.svg(
      safe_join(paths.map { |path_data| tag.path(d: path_data, "stroke-linecap": "round", "stroke-linejoin": "round") }),
      class: css_class,
      fill: "none",
      viewBox: "0 0 24 24",
      "stroke-width": stroke_width,
      stroke: "currentColor",
      "aria-hidden": "true"
    )
  end
end
