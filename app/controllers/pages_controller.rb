# Páginas institucionais: sobre nós, como anunciar, planos, privacidade e termos.
#
# Uma controller para as cinco porque nenhuma tem estado — o corpo de cada
# página é uma lista de seções em config/locales, montada pelo mesmo partial.
# A action só existe para dar nome ao template e à chave de tradução.
class PagesController < ApplicationController
  allow_unauthenticated_access

  # Data mostrada em "Última atualização" na privacidade e nos termos. Fica em
  # código, e não nos locales, para não haver duas datas que possam divergir:
  # a formatação por idioma quem faz é o l() da view.
  LAST_UPDATED_ON = Date.new(2026, 8, 17)

  def about; end

  def how_to_advertise; end

  def pricing; end

  def privacy; end

  def terms; end
end
