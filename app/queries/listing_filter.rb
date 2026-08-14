# Traduz os parâmetros da URL em um scope de Listing e alimenta os selects do
# formulário de filtro. Parâmetro desconhecido é ignorado, nunca interpolado.
class ListingFilter
  # Cada ordenação recebe o scope e devolve o scope ordenado. `year` precisa de
  # NULLS LAST: peça não tem ano e o Postgres jogaria os nulos na frente no DESC.
  SORTS = {
    "recent" => ->(scope) { scope.order(published_at: :desc) },
    "price_asc" => ->(scope) { scope.order(price_cents: :asc) },
    "price_desc" => ->(scope) { scope.order(price_cents: :desc) },
    "year_desc" => ->(scope) { scope.order(Arel.sql("listings.year DESC NULLS LAST")) }
  }.freeze

  DEFAULT_SORT = "recent".freeze

  attr_reader :category, :state, :city, :sort

  def initialize(params, scope: Listing.includes(:category))
    @scope = scope
    @category = normalize(params[:category])
    @state = normalize(params[:state])&.upcase
    @city = normalize(params[:city])
    requested_sort = params[:sort]
    @sort = SORTS.key?(requested_sort) ? requested_sort : DEFAULT_SORT

    # Cidade de outro estado viraria resultado vazio sem explicação: descarta.
    @city = nil if @city.present? && city_options.exclude?(@city)
  end

  def results
    ordered(filtered)
  end

  def applied_count
    [ category, state, city ].count(&:present?)
  end

  def applied?
    applied_count.positive?
  end

  def category_options
    Category.ordered.map { |record| [ record.name, record.slug ] }
  end

  def state_options
    Listing.distinct.order(:state).pluck(:state)
  end

  # As cidades acompanham o estado selecionado; sem estado, lista todas.
  def city_options
    scoped = state.present? ? Listing.by_state(state) : Listing.all
    scoped.distinct.order(:city).pluck(:city)
  end

  def sort_options
    SORTS.keys.map { |key| [ I18n.t("listings.sorts.#{key}"), key ] }
  end

  private
    def filtered
      scoped = @scope
      scoped = scoped.by_category(category) if category.present?
      scoped = scoped.by_state(state) if state.present?
      scoped = scoped.by_city(city) if city.present?
      scoped
    end

    def ordered(scope)
      # id como desempate mantém a paginação estável entre páginas.
      SORTS.fetch(sort).call(scope).order(id: :desc)
    end

    def normalize(value)
      value.presence&.strip
    end
end
