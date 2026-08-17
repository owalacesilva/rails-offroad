module ApplicationHelper
  DROPDOWN_ITEM = "flex w-full items-center gap-3 px-4 py-2.5 text-left text-sm " \
                  "font-semibold text-stone-600 transition hover:bg-stone-50 hover:text-stone-900".freeze

  # Item do menu de shared/_dropdown.
  def dropdown_item_class
    DROPDOWN_ITEM
  end

  # O mesmo item abrindo um bloco novo, com um filete acima: é o que separa
  # navegar de sair.
  def separated_dropdown_item_class
    "#{DROPDOWN_ITEM} mt-1 border-t border-stone-200 pt-3"
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
