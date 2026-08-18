# Traduz os parâmetros da lista de anunciantes em um scope de User e alimenta o
# painel de filtros da gestão. Mesmo desenho do AdFilter: parâmetro desconhecido
# é ignorado, nunca interpolado.
class UserFilter
  # Chave da URL -> coluna ordenável. O <th> da tabela manda a chave; a coluna
  # nunca vem do parâmetro, então não há como injetar SQL pela ordenação.
  SORTS = {
    "name" => :name,
    "email" => :email,
    "status" => :status,
    "ads" => :ads_count,
    "joined" => :created_at
  }.freeze

  DEFAULT_SORT = "joined".freeze

  DIRECTIONS = %w[asc desc].freeze

  # Cadastro mais recente primeiro é o padrão útil na moderação.
  DEFAULT_DIRECTION = "desc".freeze

  attr_reader :name, :email, :phone, :status, :min_ads, :max_ads, :sort, :direction

  def initialize(params, scope: User.all)
    @scope = scope
    @name = normalize(params[:name])
    @email = normalize(params[:email])
    # O telefone é guardado só com dígitos; a busca acompanha, para "(41) 9" e
    # "419" encontrarem a mesma coisa.
    @phone = normalize(params[:phone])&.gsub(/\D/, "").presence
    @status = allowed(params[:status], User::STATUSES.values)
    @min_ads = integer(params[:min_ads])
    @max_ads = integer(params[:max_ads])
    @sort = allowed(params[:sort], SORTS.keys, DEFAULT_SORT)
    @direction = allowed(params[:dir], DIRECTIONS, DEFAULT_DIRECTION)
  end

  def results
    ordered(filtered)
  end

  # Quantos critérios estão de fato aplicados. A ordenação não conta: ela sempre
  # tem um valor e não restringe nada.
  def applied_count
    [ name, email, phone, status, min_ads, max_ads ].count { |value| value.present? }
  end

  def applied?
    applied_count.positive?
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

  # Os parâmetros que a paginação e os links de ordenação precisam preservar.
  def to_params
    { name: name, email: email, phone: phone, status: status,
      min_ads: min_ads, max_ads: max_ads, sort: sort, dir: direction }.compact_blank
  end

  private
    # Valor fora da lista cai no padrão em vez de virar consulta vazia — ou, no
    # caso da ordenação, de chegar ao ORDER BY.
    def allowed(value, permitted, fallback = nil)
      permitted.include?(value) ? value : fallback
    end

    def filtered
      scoped = @scope
      scoped = scoped.where("users.name LIKE ?", like(name)) if name.present?
      scoped = scoped.where("users.email LIKE ?", like(email)) if email.present?
      scoped = scoped.where("users.phone LIKE ?", like(phone)) if phone.present?
      scoped = scoped.where(status: status) if status.present?
      scoped = by_ad_count(scoped)
      scoped
    end

    def by_ad_count(scoped)
      scoped = scoped.where(ads_count: min_ads..) if min_ads
      scoped = scoped.where(ads_count: ..max_ads) if max_ads
      scoped
    end

    def ordered(scoped)
      # id como desempate mantém a paginação estável entre páginas.
      scoped.order(SORTS.fetch(sort) => direction).order(id: :desc)
    end

    # sanitize_sql_like escapa % e _ digitados: sem isso, procurar por "%"
    # traria a lista inteira.
    def like(term)
      "%#{User.sanitize_sql_like(term)}%"
    end

    def normalize(value)
      value.presence&.strip
    end

    def integer(value)
      Integer(value, exception: false)
    end
end
