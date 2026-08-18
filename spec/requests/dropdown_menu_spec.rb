require "rails_helper"

# Os menus suspensos do canto direito do header — portal, painel do anunciante e
# moderação — passaram a levar ícone em cada item.
RSpec.describe "Menus do header", type: :request do
  def menu_items(body)
    menus = body.scan(%r{<nav class="absolute[^"]*">(.*?)</nav>}m).flatten

    # to_enum e não scan: a expressão tem grupo (o backreference que fecha a
    # tag), e scan com grupo devolve os grupos, não o trecho inteiro.
    item = %r{<(a|button)\b[^>]*class="flex w-full.*?</\1>}m

    menus.flat_map { |menu| menu.to_enum(:scan, item).map { Regexp.last_match(0) } }
  end

  # Um item sem ícone no meio dos outros nasce recuado a menos e quebra a coluna
  # do texto, então a checagem é por ausência: nenhum item do menu sem <svg>.
  # A contagem vai junto para o teste não passar por não ter achado item nenhum.
  def expect_every_item_to_have_an_icon(body)
    items = menu_items(body)

    expect(items.size).to be >= 5
    expect(items.reject { |markup| markup.include?("<svg") }).to be_empty
  end

  def icon_path(name)
    IconHelper::UI_ICONS.fetch(name).first
  end

  describe "menu do portal" do
    it "leva ícone em todo item" do
      get root_path

      expect_every_item_to_have_an_icon(response.body)
    end

    it "marca início, blog e entrar" do
      get root_path

      expect(response.body).to include(icon_path(:home), icon_path(:document), icon_path(:user))
    end

    it "marca sair quando há sessão" do
      sign_in(create(:user))

      get root_path

      expect(response.body).to include(icon_path(:logout))
    end
  end

  describe "menu do painel do anunciante" do
    before { sign_in(create(:user)) }

    it "leva ícone em todo item" do
      get account_path

      expect_every_item_to_have_an_icon(response.body)
    end

    it "marca anúncios, propostas e novo anúncio" do
      get account_path

      expect(response.body).to include(icon_path(:queue), icon_path(:inbox), icon_path(:plus))
    end

    # O contador de anúncios e propostas fica ao lado do rótulo, dentro do
    # mesmo item — o ícone entrou sem empurrá-lo para fora.
    it "mantém o contador ao lado do rótulo" do
      create(:ad, user: User.last)

      get account_path

      expect(response.body).to include(I18n.t("dashboard.nav.ads"))
    end
  end

  describe "menu da moderação" do
    before { sign_in_admin(create(:admin)) }

    it "leva ícone em todo item" do
      get admin_root_path

      expect_every_item_to_have_an_icon(response.body)
    end

    it "marca filas, eventos, blog e anunciantes" do
      get admin_root_path

      expect(response.body).to include(icon_path(:queue), icon_path(:calendar),
                                       icon_path(:document), icon_path(:users))
    end
  end

  # O menu de idioma aparece dentro dos três: um item sem ícone ali desalinha
  # todos os outros.
  it "leva ícone também nas opções de idioma" do
    sign_in(create(:user))

    get account_path

    expect(response.body).to include(icon_path(:globe))
  end
end
