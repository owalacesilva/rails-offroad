module Dashboard
  # Assinatura do plano Premium. `new` mostra a situação e o botão; `create` abre
  # a cobrança no PagBank e manda o navegador para lá.
  #
  # Quem concede o Premium não é esta controller: ela só cria a cobrança. O
  # Premium vem da notificação assinada (PagseguroNotificationsController), porque
  # voltar do PagBank não é prova de pagamento — o retorno é só o navegador.
  class SubscriptionsController < BaseController
    before_action :load_gateway

    def new
      @premium_until = current_user.premium_until
    end

    def create
      subscription = Subscription.open_for(current_user, amount_cents: PagesHelper::PLAN_PRICES.fetch("premium"))
      pay_url = @gateway.create_checkout(order_for(subscription))

      return redirect_to pay_url, allow_other_host: true if pay_url

      # Cobrança que não chegou a existir no PagBank não fica na tabela: ela
      # apareceria como pendente para sempre, sem nada do outro lado.
      subscription.destroy
      redirect_to account_premium_path, alert: t("dashboard.premium.failure")
    end

    private
      # Sem token configurado a assinatura não existe: para quem está do lado de
      # fora, é o mesmo que a rota não existir — como em OauthController.
      def load_gateway
        @gateway = Pagseguro.build

        raise ActionController::RoutingError, "PagSeguro not configured" unless @gateway
      end

      def order_for(subscription)
        Pagseguro::Order.new(
          reference_id: subscription.gateway_reference,
          amount_cents: subscription.amount_cents,
          # O nome vai na fatura e na tela do PagBank, então é lido no idioma
          # padrão do portal, não no que a pessoa escolheu na sessão.
          item_name: t("dashboard.premium.item", locale: I18n.default_locale),
          redirect_url: account_premium_url,
          notification_url: pagseguro_notifications_url
        )
      end
  end
end
