class Ad < ApplicationRecord
  # `new` colidiria com Ad.new, daí new_arrival.
  BADGES = { prepared: 0, featured: 1, new_arrival: 2 }.freeze

  # Fluxo de moderação: nasce em pending, um admin aprova ou rejeita.
  STATUSES = { draft: "draft", pending: "pending", approved: "approved", rejected: "rejected" }.freeze

  # A cardinalidade "has (3 to 10)" do diagrama, agora de fato validada.
  IMAGE_COUNT = (3..10).freeze

  RELATED_LIMIT = 4

  belongs_to :user
  belongs_to :category
  # Quem avaliou. Nulo enquanto ninguém moderou.
  belongs_to :admin, optional: true

  has_many :proposals, dependent: :destroy
  # Todas as fotos, inclusive as bloqueadas: é o que a moderação precisa ver.
  has_many :ad_images, -> { ordered }, dependent: :destroy, inverse_of: :ad
  # O que o portal exibe. Foto bloqueada some daqui e da contagem que valida o
  # anúncio aprovado — é o que faz o bloqueio ter consequência.
  has_many :visible_images, -> { visible.ordered }, class_name: "AdImage",
                            inverse_of: :ad, dependent: nil
  has_many :technical_spec_values, dependent: :destroy, inverse_of: :ad
  has_many :spec_attributes, through: :technical_spec_values, source: :spec_attribute

  enum :badge, BADGES, prefix: true
  enum :status, STATUSES

  before_validation :assign_slug

  validates :title, presence: true
  validates :slug, presence: true, uniqueness: { case_sensitive: false }
  validates :city, presence: true
  validates :state, presence: true, length: { is: 2 }
  # A validação fica no leitor em reais, e não em price_cents, para a mensagem
  # de erro falar a língua do formulário.
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
  validate :category_specifications_complete, if: -> { validation_context == :submission }

  # Só anúncio aprovado, e só de anunciante ativo, aparece publicamente:
  # bloquear um anunciante tira os anúncios dele do ar sem mexer em cada um.
  # Subconsulta em vez de joins, para não conflitar com o includes das listagens.
  scope :published, -> { where(status: STATUSES[:approved], user: User.active) }
  scope :recent, -> { order(published_at: :desc) }
  # A régua "Mais Vistos" da home. O desempate por data evita que um acervo novo,
  # em que todo mundo ainda está zerado, saia em ordem indefinida do MySQL.
  scope :most_viewed, -> { order(views_count: :desc, published_at: :desc) }
  # Fotos prontas para exibir. O anexo entra no preload junto porque AdImage#url
  # pergunta se há blob: sem isto seria uma consulta por foto em cada listagem.
  scope :with_photos, -> { includes(visible_images: { file_attachment: :blob }) }
  # A fila de moderação precisa das bloqueadas junto, para poder desbloquear.
  scope :with_all_photos, -> { includes(ad_images: { file_attachment: :blob }) }
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

  # A coluna é price_cents (inteiro); a aplicação inteira fala em reais.
  def price
    self.class.amount_or_input(price_cents, @price_input)
  end

  def price=(value)
    @price_input = value
    self.price_cents = self.class.to_cents(value)
  end

  # A URL usa a slug, não o id.
  def to_param
    slug
  end

  # A descrição chega como HTML do editor do formulário e é limpa na entrada,
  # não na exibição: assim o banco só guarda o que já está dentro da lista, e
  # nenhuma tela precisa lembrar de sanitizar de novo (a de exibição sanitiza
  # mesmo assim, por cima).
  #
  # Texto puro atravessa sem virar HTML — é o que o seed grava e o que sobra de
  # quem preenche o formulário com o JavaScript desligado.
  def description=(value)
    super(self.class.sanitize_rich_text(value))
  end

  def cover_image
    visible_images.first
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

  # O recado é opcional na assinatura mas cobrado no formulário da moderação:
  # rejeitar sem dizer por quê deixa o anunciante sem o que corrigir.
  def reject(admin, note: nil)
    update(status: :rejected, admin: admin, reviewed_at: Time.current, moderation_note: note)
  end

  # Tira uma foto do ar sem mexer no resto do anúncio.
  #
  # Se sobrar menos que o mínimo, o anúncio aprovado volta para a fila: aprovado
  # com duas fotos é um estado que a validação não aceita, e deixá-lo no portal
  # seria publicar um anúncio que a própria moderação não conseguiria reaprovar.
  def block_image(image, admin, note: nil)
    now = Time.current
    image.update!(blocked_at: now)
    review = { admin: admin, reviewed_at: now }
    review[:moderation_note] = note if note.present?
    review[:status] = :pending if demote_after_block?

    update(review)
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
    # Gerada uma vez e nunca mais: mudar o título de um anúncio publicado não
    # pode quebrar o link que ele já espalhou por aí.
    def assign_slug
      return if slug.present? || title.blank?

      self.slug = self.class.unique_slug(title.parameterize.presence || "anuncio")
    end

    # "Selecione todos os atributos": o conjunto exigido é o da categoria
    # escolhida. Cobrado só na submissão pelo formulário — rascunho e seed
    # seguem podendo ficar incompletos, como no caso das fotos.
    def category_specifications_complete
      return if category.blank?

      filled = technical_spec_values.filter_map { |spec| spec.attribute_id if spec.value.present? }
      missing = category.spec_attributes.ordered.reject { |attribute| filled.include?(attribute.id) }
      return if missing.empty?

      errors.add(:base, :missing_specifications, names: missing.map(&:label).to_sentence)
    end

    # Conta só o que está no ar: foto bloqueada não sustenta anúncio aprovado.
    def image_count_within_bounds
      return if IMAGE_COUNT.cover?(countable_images.size)

      errors.add(:ad_images, :invalid_count, min: IMAGE_COUNT.min, max: IMAGE_COUNT.max)
    end

    # Só anúncio no ar precisa voltar para a fila. Rascunho e rejeitado já não
    # aparecem no portal, e promovê-los a "pendente" desfaria o que a moderação
    # tinha decidido antes.
    def demote_after_block?
      approved? && !IMAGE_COUNT.cover?(visible_images.reload.size)
    end

    # Em registro novo as fotos ainda estão só na memória, e `visible_images`
    # faria uma consulta que não enxerga nenhuma delas.
    def countable_images
      new_record? ? ad_images.reject(&:blocked?) : visible_images
    end
end
