# Traduz os parâmetros da fila de moderação em um scope de Ad e alimenta o
# painel de filtros da gestão. Mesmo desenho do AdFilter da vitrine e do
# UserFilter: parâmetro desconhecido é ignorado, nunca interpolado.
#
# É uma classe à parte do AdFilter porque as duas telas perguntam coisas
# diferentes: a vitrine parte de Ad.published e filtra por quem compra; a fila
# parte da tabela inteira e filtra por quem modera — inclusive o rascunho e o
# rejeitado, que a vitrine nunca vê.
class AdQueueFilter
  # Chave da URL -> tabela e coluna ordenável. O <th> manda a chave; a coluna
  # sai daqui e nunca do parâmetro, então não há como injetar SQL pela
  # ordenação.
  SORTS = {
    "title" => [ :ads, :title ],
    "advertiser" => [ :users, :name ],
    "category" => [ :categories, :position ],
    "price" => [ :ads, :price_cents ],
    "views" => [ :ads, :views_count ],
    "created" => [ :ads, :created_at ]
  }.freeze

  # Mais recente primeiro: numa fila, o que chegou por último é o que ainda não
  # foi olhado.
  DEFAULT_SORT = "created".freeze

  DIRECTIONS = %w[asc desc].freeze

  DEFAULT_DIRECTION = "desc".freeze

  # A aba "todas". Não é um status de Ad: é a ausência de recorte por status, e
  # precisa de um valor próprio porque a ausência do parâmetro significa outra
  # coisa — a fila de pendentes, que é onde a moderação começa o dia.
  ALL = "all".freeze

  attr_reader :query, :status, :category, :advertiser, :state, :min_price, :max_price, :sort, :direction

  def initialize(params, scope: Ad.all)
    @scope = scope
    @query = normalize(params[:q])
    # Status desconhecido cai na fila padrão em vez de listar nada: é a aba que
    # o moderador abre primeiro.
    @status = allowed(params[:status], Ad::STATUSES.values + [ ALL ], Ad::STATUSES[:pending])
    @category = normalize(params[:category])
    @advertiser = normalize(params[:advertiser])
    @state = allowed(params[:state]&.upcase, User::BRAZILIAN_STATES)
    @min_price = money(params[:min_price])
    @max_price = money(params[:max_price])
    @sort = allowed(params[:sort], SORTS.keys, DEFAULT_SORT)
    @direction = allowed(params[:dir], DIRECTIONS, DEFAULT_DIRECTION)
  end

  def results
    ordered(filtered)
  end

  # Quantos critérios estão de fato aplicados. Status fica de fora: ele é a aba
  # aberta, sempre tem valor e não é o que o botão de limpar desfaz.
  def applied_count
    [ query, category, advertiser, state, min_price, max_price ].count(&:present?)
  end

  def applied?
    applied_count.positive?
  end

  def all_statuses?
    status == ALL
  end

  def sorted_by?(key)
    sort == key
  end

  # A direção que o link do cabeçalho deve pedir: inverte a atual na coluna já
  # ordenada, e começa em ascendente numa coluna nova.
  def next_direction(key)
    return "asc" unless sorted_by?(key)

    direction == "asc" ? "desc" : "asc"
  end

  # Os preços voltam ao formulário em reais, que é como foram digitados.
  def to_params
    { q: query, status: status, category: category, advertiser: advertiser, state: state,
      min_price: as_amount(min_price), max_price: as_amount(max_price),
      sort: sort, dir: direction }.compact_blank
  end

  # O mesmo estado sem os critérios de busca: é o que as abas de situação
  # precisam preservar ao trocar de fila.
  def sort_params
    { sort: sort, dir: direction }
  end

  # Todas as categorias, e não só as que têm anúncio: a fila lida com o que
  # ainda não está publicado.
  def category_options
    Category.ordered.map { |record| [ record.name, record.slug ] }
  end

  private
    def allowed(value, permitted, fallback = nil)
      permitted.include?(value) ? value : fallback
    end

    def filtered
      scoped = all_statuses? ? @scope : @scope.where(status: status)
      scoped = scoped.matching(query) if query.present?
      scoped = scoped.by_category(category) if category.present?
      scoped = scoped.by_state(state) if state.present?
      scoped = by_advertiser(scoped)
      by_price(scoped)
    end

    # Nome ou e-mail do anunciante na mesma caixa: quem modera procura pelos
    # dois sem querer escolher em qual campo digitar.
    def by_advertiser(scoped)
      return scoped if advertiser.blank?

      term = "%#{User.sanitize_sql_like(advertiser)}%"

      scoped.joins(:user).where("users.name LIKE :term OR users.email LIKE :term", term: term)
    end

    def by_price(scoped)
      scoped = scoped.where(price_cents: min_price..) if min_price
      scoped = scoped.where(price_cents: ..max_price) if max_price
      scoped
    end

    def ordered(scoped)
      table, column = SORTS.fetch(sort)

      # joins e não includes: a ordenação por nome do anunciante e por posição
      # da categoria precisa das duas tabelas no FROM. Quem monta o scope já
      # pediu o preload delas.
      # id como desempate mantém a paginação estável entre páginas.
      scoped.joins(:user, :category).order(table => { column => direction }).order(id: :desc)
    end

    def normalize(value)
      value.presence&.strip
    end

    # Digitado em reais, guardado em centavos — como em todo campo de dinheiro
    # do portal.
    def money(value)
      cents = ApplicationRecord.to_cents(value)

      cents if cents.is_a?(Integer) && cents.positive?
    end

    # De volta a reais para o campo do formulário, sem o ".0" que um BigDecimal
    # redondo arrasta para a URL.
    def as_amount(cents)
      return unless cents

      amount = ApplicationRecord.to_amount(cents)

      amount.frac.zero? ? amount.to_i : amount.to_f
    end
end
