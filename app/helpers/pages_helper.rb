module PagesHelper
  # Mensalidade de cada plano, em centavos como qualquer valor do portal.
  #
  # Fica em código, e não nos locales, pelo mesmo motivo de
  # PagesController::LAST_UPDATED_ON: são dois arquivos de idioma, e preço
  # escrito duas vezes é preço que um dia divergirá. O que os locales trazem é
  # o texto do plano; quanto custa é um número só, formatado pelo locale.
  #
  # Vive no helper e não na controller porque é dado de apresentação e só a
  # view o consome — o mesmo lugar de HomeHelper::QUICK_SEARCHES.
  PLAN_PRICES = { "free" => 0, "premium" => 4_990 }.freeze

  # O preço do plano pronto para a tela. Zero não passa pelo formatador: sai
  # como "R$ 0" (pages.pricing.free_price), sem os centavos que o preço de um
  # anúncio precisa mostrar — ali eles existem de verdade, aqui só fariam ruído
  # ao lado de "para sempre".
  def plan_price(key)
    cents = PLAN_PRICES.fetch(key.to_s)
    return t("pages.pricing.free_price") if cents.zero?

    ad_price(ApplicationRecord.to_amount(cents))
  end

  # O plano gratuito não é assinatura: o botão leva direto ao formulário de
  # anúncio, como o "Anunciar" do header — quem não está logado cai no login e
  # volta. O Premium não tem checkout, então conversa com a gente por e-mail.
  def plan_cta_path(key)
    return new_account_ad_path if key.to_s == "free"

    "mailto:#{t('layout.footer.contact.email')}"
  end
end
