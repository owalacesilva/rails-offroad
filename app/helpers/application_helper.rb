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
end
