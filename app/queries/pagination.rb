# Paginação por offset, sem dependência externa. Página fora do intervalo é
# corrigida para a borda mais próxima em vez de devolver lista vazia.
class Pagination
  PER_PAGE = 12

  attr_reader :page, :per_page, :total_count

  def initialize(scope, page:, per_page: PER_PAGE)
    @scope = scope
    @per_page = per_page
    # except(:order) porque ORDER BY em consulta agregada quebra no Postgres.
    @total_count = scope.except(:order).count
    @page = page.to_i.clamp(1, total_pages)
  end

  def records
    @scope.offset((page - 1) * per_page).limit(per_page)
  end

  def total_pages
    [ (total_count.to_f / per_page).ceil, 1 ].max
  end

  def many_pages?
    total_pages > 1
  end

  def first_page?
    page == 1
  end

  def last_page?
    page >= total_pages
  end

  def from
    total_count.zero? ? 0 : ((page - 1) * per_page) + 1
  end

  def to
    [ page * per_page, total_count ].min
  end
end
