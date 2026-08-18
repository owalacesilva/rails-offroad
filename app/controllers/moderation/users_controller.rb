module Moderation
  # Gestão de anunciantes: lista, busca e mudança de situação.
  #
  # Deliberadamente sem edição de dados pessoais — nome, e-mail e telefone são
  # do anunciante, que os altera no próprio perfil. O que a moderação decide é
  # se a conta continua ativa, e isso já tira ou devolve os anúncios ao portal
  # (ver Ad.published).
  class UsersController < BaseController
    def index
      @status = requested_status
      @query = params[:q].to_s.strip
      @counts = User.group(:status).count
      @users = filtered.order(created_at: :desc)
    end

    def status
      user = User.find(params[:id])
      user.update!(status: requested_change)
      status = user.status

      redirect_to admin_users_path(status: status),
                  notice: t("admin.users.status.success", name: user.name,
                                                          status: t("admin.users.statuses.#{status}"))
    end

    private
      # Sem filtro na URL mostra todos; situação desconhecida também, em vez de
      # devolver lista vazia sem explicação.
      def requested_status
        requested = params[:status]

        requested if User::STATUSES.key?(requested&.to_sym)
      end

      # Situação inválida no POST não vira erro 500: cai em `active`, que é o
      # estado neutro.
      def requested_change
        wanted = params[:to]

        User::STATUSES.key?(wanted&.to_sym) ? wanted : User::STATUSES[:active]
      end

      def filtered
        scope = @status ? User.where(status: @status) : User.all
        return scope if @query.blank?

        scope.where("users.name LIKE :term OR users.email LIKE :term",
                    term: "%#{User.sanitize_sql_like(@query)}%")
      end
  end
end
