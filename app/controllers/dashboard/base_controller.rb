module Dashboard
  # Toda a área do anunciante compartilha o mesmo chrome claro, próprio, em vez
  # de herdar o header e o footer escuros do portal.
  class BaseController < ApplicationController
    # Qual item da navegação lateral fica ativo, derivado da própria controller.
    SECTIONS = {
      "dashboard" => :dashboard,
      "ads" => :ads,
      "proposals" => :proposals,
      "profiles" => :profile
    }.freeze

    layout "account"

    helper_method :account_section

    private
      def account_section
        SECTIONS.fetch(controller_name, :dashboard)
      end
  end
end
