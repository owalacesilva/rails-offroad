module Moderation
  # Gestão de anunciantes: tabela com filtro, ordenação, paginação e ação em
  # lote sobre as linhas selecionadas.
  #
  # Deliberadamente sem edição de dados pessoais — nome, e-mail e telefone são
  # do anunciante, que os altera no próprio perfil. O que a moderação decide é
  # se a conta continua ativa, e isso já tira ou devolve os anúncios ao portal
  # (ver Ad.published).
  class UsersController < BaseController
    PER_PAGE = 20

    def index
      @filter = UserFilter.new(filter_params)
      @counts = User.group(:status).count
      @pagination = Pagination.new(@filter.results, page: params[:page], per_page: PER_PAGE)
      @users = @pagination.records
    end

    def status
      user = User.find(params[:id])
      user.update!(status: requested_change)
      status = user.status

      redirect_back_to_list notice: t("admin.users.status.success", name: user.name,
                                                                    status: t("admin.users.statuses.#{status}"))
    end

    # As caixas de seleção da tabela: muda a situação de todos os marcados de
    # uma vez. Um UPDATE só, sem callback — não há nenhum em User#status.
    def bulk_status
      changed = User.where(id: params[:user_ids]).update_all(status: requested_change)

      return redirect_back_to_list(alert: t("admin.users.bulk.none")) if changed.zero?

      redirect_back_to_list notice: t("admin.users.bulk.success", count: changed,
                                                                  status: t("admin.users.statuses.#{requested_change}"))
    end

    private
      # Volta para a lista como ela estava: filtro, ordenação e página.
      def redirect_back_to_list(flash_message)
        redirect_to admin_users_path(params.fetch(:list, {}).permit!.to_h), **flash_message
      end

      # Situação inválida não vira erro 500: cai em `active`, o estado neutro.
      def requested_change
        wanted = params[:to]

        User::STATUSES.key?(wanted&.to_sym) ? wanted : User::STATUSES[:active]
      end

      def filter_params
        params.permit(:name, :email, :phone, :status, :min_ads, :max_ads, :sort, :dir)
      end
  end
end
