# Notificação de pagamento do PagBank.
#
# É a única coisa em que a aplicação confia para conceder o Premium: quem volta
# do checkout traz só um navegador, e navegador se falsifica com uma URL. Quem
# diz que o dinheiro entrou é este POST, e o que prova que ele é do PagBank é a
# assinatura SHA256 do corpo (ver Pagseguro#authentic?).
class PagseguroNotificationsController < ApplicationController
  allow_unauthenticated_access
  # Quem chama é o servidor do PagBank, que não tem sessão nem token de CSRF.
  skip_forgery_protection

  before_action :load_gateway
  before_action :verify_authenticity

  # Sempre 200 quando a notificação é autêntica, inclusive para referência
  # desconhecida ou situação que não é desfecho: o PagBank reenvia o que não
  # respondeu 2xx, e reenviar não faria a linha aparecer.
  def create
    subscription&.apply_gateway_status(gateway_status)

    head :ok
  end

  private
    def load_gateway
      @gateway = Pagseguro.build

      raise ActionController::RoutingError, "PagSeguro not configured" unless @gateway
    end

    # raw_post, e não os params já convertidos: o hash é do texto exatamente
    # como chegou, e qualquer reserialização muda um espaço e o invalida.
    def verify_authenticity
      return if @gateway.authentic?(request.raw_post, request.headers["x-authenticity-token"])

      head :unauthorized
    end

    def subscription
      Subscription.find_by(gateway_reference: params[:reference_id])
    end

    # A situação mora na cobrança, não no pedido: um pedido pode ter mais de uma
    # (uma recusada e outra paga), e é a última que conta.
    def gateway_status
      Array(params[:charges]).last&.dig(:status)
    end
end
