# Traduz os parâmetros da URL em um scope de Ad e alimenta os selects do
# formulário de filtro. Parâmetro desconhecido é ignorado, nunca interpolado.
class AdFilter
  # Cada ordenação recebe o scope e devolve o scope ordenado. Em `year` os nulos
  # (peça não tem ano) ficam no fim sem cláusula extra: o MySQL ordena NULL como
  # o menor valor, então o DESC já o joga para o final.
  SORTS = {
    "recent" => ->(scope) { scope.order(published_at: :desc) },
    "price_asc" => ->(scope) { scope.order(price: :asc) },
    "price_desc" => ->(scope) { scope.order(price: :desc) },
    "year_desc" => ->(scope) { scope.order(year: :desc) }
  }.freeze

  DEFAULT_SORT = "recent".freeze

  attr_reader :query, :category, :state, :city, :sort

  # Só anúncio aprovado entra na vitrine — o filtro nunca enxerga a fila de
  # moderação.
  def initialize(params, scope: Ad.published.with_photos.includes(:category))
    @scope = scope
    @query = normalize(params[:q])
    @category = normalize(params[:category])
    @state = normalize(params[:state])&.upcase
    @city = normalize(params[:city])
    @sort = resolved_sort(params[:sort])

    # Cidade de outro estado viraria resultado vazio sem explicação: descarta.
    @city = nil if @city.present? && city_options.exclude?(@city)
  end

  def results
    ordered(filtered)
  end

  def applied_count
    [ query, category, state, city ].count(&:present?)
  end

  def applied?
    applied_count.positive?
  end

  def category_options
    Category.ordered.map { |record| [ record.name, record.slug ] }
  end

  def state_options
    Ad.published.distinct.order(:state).pluck(:state)
  end

  # As cidades acompanham o estado selecionado; sem estado, lista todas.
  def city_options
    scoped = Ad.published
    scoped = scoped.by_state(state) if state.present?

    scoped.distinct.order(:city).pluck(:city)
  end

  def sort_options
    SORTS.keys.map { |key| [ I18n.t("ads.sorts.#{key}"), key ] }
  end

  private
    def filtered
      scoped = @scope
      scoped = scoped.matching(query) if query.present?
      scoped = scoped.by_category(category) if category.present?
      scoped = scoped.by_state(state) if state.present?
      scoped = scoped.by_city(city) if city.present?
      scoped
    end

    def ordered(scope)
      # id como desempate mantém a paginação estável entre páginas.
      SORTS.fetch(sort).call(scope).order(id: :desc)
    end

    # Extraído do initialize para o método caber no limite de statements do reek.
    def resolved_sort(requested)
      SORTS.key?(requested) ? requested : DEFAULT_SORT
    end

    def normalize(value)
      value.presence&.strip
    end
end
