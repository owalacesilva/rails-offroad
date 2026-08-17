class Ad < ApplicationRecord
  # `new` colidiria com Ad.new, daí new_arrival.
  BADGES = { prepared: 0, featured: 1, new_arrival: 2 }.freeze

  # Fluxo de moderação: nasce em pending, um admin aprova ou rejeita.
  STATUSES = { draft: "draft", pending: "pending", approved: "approved", rejected: "rejected" }.freeze

  # A cardinalidade "has (3 to 10)" do diagrama, agora de fato validada.
  IMAGE_COUNT = (3..10).freeze

  RELATED_LIMIT = 4

  # O que a descrição pode conter: exatamente os cinco controles do editor do
  # formulário (negrito, itálico, as duas listas e H3) mais os blocos que eles
  # produzem. Nenhum atributo passa — nem style, nem class, nem href: o campo
  # descreve um veículo, não é uma página.
  DESCRIPTION_TAGS = %w[p br strong em b i ul ol li h3].freeze

  belongs_to :user
  belongs_to :category
  # Quem avaliou. Nulo enquanto ninguém moderou.
  belongs_to :admin, optional: true

  has_many :proposals, dependent: :destroy
  has_many :ad_images, -> { ordered }, dependent: :destroy, inverse_of: :ad
  has_many :technical_spec_values, dependent: :destroy, inverse_of: :ad
  has_many :spec_attributes, through: :technical_spec_values, source: :spec_attribute

  enum :badge, BADGES, prefix: true
  enum :status, STATUSES

  validates :title, presence: true
  validates :city, presence: true
  validates :state, presence: true, length: { is: 2 }
  validates :price, numericality: { greater_than: 0 }
  # Ano no futuro não é aceito: o teto é o ano corrente. Antes o limite era
  # ano + 1, para o modelo-ano adiantado que a indústria automotiva usa; a regra
  # agora é a literal, então uma picape "2027" anunciada em 2026 é recusada.
  validates :year,
            numericality: {
              only_integer: true,
              greater_than: 1900,
              less_than_or_equal_to: ->(_ad) { Date.current.year }
            },
            allow_nil: true
  # Fotos são cobradas em dois momentos: no anúncio aprovado, que já está no ar,
  # e na submissão pelo formulário do anunciante, que cai direto na fila — sem
  # elas o moderador receberia um anúncio que não tem como aprovar. Rascunho e
  # seed seguem podendo ficar incompletos.
  #
  # As duas condições moram no mesmo `validate` de propósito: registrar o mesmo
  # método duas vezes não soma callbacks, a segunda chamada substitui a primeira.
  validate :image_count_within_bounds, if: -> { approved? || validation_context == :submission }

  # Só anúncio aprovado aparece publicamente. É o ponto do fluxo de moderação.
  scope :published, -> { where(status: STATUSES[:approved]) }
  scope :recent, -> { order(published_at: :desc) }
  # A régua "Mais Vistos" da home. O desempate por data evita que um acervo novo,
  # em que todo mundo ainda está zerado, saia em ordem indefinida do MySQL.
  scope :most_viewed, -> { order(views_count: :desc, published_at: :desc) }
  # Fotos prontas para exibir. O anexo entra no preload junto porque AdImage#url
  # pergunta se há blob: sem isto seria uma consulta por foto em cada listagem.
  scope :with_photos, -> { includes(ad_images: { file_attachment: :blob }) }
  # Subconsulta em vez de joins: evita conflito com o includes(:category) da listagem.
  scope :by_category, ->(slug) { where(category: Category.where(slug: slug)) }
  scope :by_state, ->(state) { where(state: state) }
  scope :by_city, ->(city) { where(city: city) }
  # Busca por texto no título. sanitize_sql_like escapa % e _ digitados pelo
  # usuário: sem isso, procurar por "100%" viraria curinga e traria o acervo
  # inteiro. A comparação é indiferente a maiúsculas pela collation do MySQL.
  scope :matching, ->(term) { where("ads.title LIKE ?", "%#{sanitize_sql_like(term)}%") }

  # Antes vinha de um hash jsonb ordenado por constante; agora a ordem é a
  # coluna `position` do atributo.
  def ordered_specifications
    technical_spec_values.includes(:spec_attribute).sort_by(&:position).map(&:to_pair)
  end

  # Vírgula do formulário vira ponto antes do cast (ver ApplicationRecord).
  def price=(value)
    super(self.class.normalize_decimal(value))
  end

  # A descrição chega como HTML do editor do formulário e é limpa na entrada,
  # não na exibição: assim o banco só guarda o que já está dentro da lista, e
  # nenhuma tela precisa lembrar de sanitizar de novo (a de exibição sanitiza
  # mesmo assim, por cima).
  #
  # Texto puro atravessa sem virar HTML — é o que o seed grava e o que sobra de
  # quem preenche o formulário com o JavaScript desligado.
  def description=(value)
    super(self.class.sanitize_description(value))
  end

  def self.sanitize_description(value)
    return value if value.blank?

    Rails::HTML5::SafeListSanitizer.new.sanitize(value.to_s, tags: DESCRIPTION_TAGS, attributes: [])
  end

  def cover_image
    ad_images.first
  end

  # UPDATE atômico direto na coluna: contar visualização não pode disputar com
  # quem estiver editando o anúncio, nem falhar porque o registro está inválido.
  #
  # Deliberadamente ingênuo — recarga e robô contam igual. Visualização única
  # exigiria uma tabela de visitas, que é justamente o que o contador evita.
  def record_view
    self.class.increment_counter(:views_count, id)
  end

  # Aprova e publica em um passo: registrar quem avaliou é parte da aprovação.
  # Devolve false em vez de estourar — anúncio sem as 3 fotos não passa, e a
  # controller precisa mostrar isso na fila de moderação.
  def approve(admin)
    now = Time.current

    update(status: :approved, admin: admin, reviewed_at: now, published_at: published_at || now)
  end

  def reject(admin)
    update(status: :rejected, admin: admin, reviewed_at: Time.current)
  end

  # Mesma categoria, exceto o próprio anúncio. Deliberadamente simples: não
  # pondera estado nem faixa de preço.
  def related(limit: RELATED_LIMIT)
    self.class.published
        .with_photos.includes(:category)
        .where(category_id: category_id)
        .where.not(id: id)
        .recent
        .limit(limit)
  end

  private
    def image_count_within_bounds
      return if IMAGE_COUNT.cover?(ad_images.size)

      errors.add(:ad_images, :invalid_count, min: IMAGE_COUNT.min, max: IMAGE_COUNT.max)
    end
end
