module ApplicationHelper
  DROPDOWN_ITEM = "flex w-full items-center gap-3 px-4 py-2.5 text-left text-sm font-semibold transition".freeze

  # A cor do item e a do seu ícone, juntas. As três variantes trazem o conjunto
  # inteiro em vez de sobrescrever a cor da variante padrão: entre duas classes
  # Tailwind da mesma propriedade quem vence é a que sair depois na folha
  # construída, não a que vier depois no atributo — o mesmo motivo pelo qual
  # share_controller acrescenta a classe de exibição em vez de alternar `hidden`.
  DROPDOWN_TONES = {
    default: [ "text-stone-600 hover:bg-stone-50 hover:text-stone-900", "text-stone-400" ],
    positive: [ "text-emerald-700 hover:bg-emerald-50 hover:text-emerald-800", "text-emerald-500" ],
    danger: [ "text-red-600 hover:bg-red-50 hover:text-red-700", "text-red-400" ]
  }.freeze

  # Item do menu de shared/_dropdown e de shared/_row_menu.
  def dropdown_item_class(tone: :default)
    "#{DROPDOWN_ITEM} #{DROPDOWN_TONES.fetch(tone).first}"
  end

  # O ícone do item acompanha o tom, um degrau mais claro que o texto.
  def dropdown_icon_class(tone: :default)
    "h-4 w-4 shrink-0 #{DROPDOWN_TONES.fetch(tone).last}"
  end

  # O filete que abre um bloco novo dentro do menu: é o que separa navegar de
  # sair. Vive sozinho porque dropdown_link já traz a classe do item e só
  # precisa do acréscimo.
  def dropdown_separator_class
    "mt-1 border-t border-stone-200 pt-3"
  end

  # O item e o filete juntos, para quem monta o link na mão.
  def separated_dropdown_item_class
    "#{dropdown_item_class} #{dropdown_separator_class}"
  end

  # Cor da faixa de flash do <noscript> em shared/_flash. Só duas: "alert" é
  # tudo que deu errado, e qualquer outra chave é aviso de que deu certo.
  def flash_banner_class(type)
    if type.to_s == "alert"
      "border-red-300 bg-red-50 text-red-700"
    else
      "border-emerald-300 bg-emerald-50 text-emerald-700"
    end
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
      pricing: pricing_path,
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
