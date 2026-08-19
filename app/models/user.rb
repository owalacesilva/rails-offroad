class User < ApplicationRecord
  BRAZILIAN_STATES = %w[
    AC AL AP AM BA CE DF ES GO MA MT MS MG PA PB PR PE PI RJ RN RS RO RR SC SP SE TO
  ].freeze

  # Prazo do link de confirmação. Dois dias cobrem quem se cadastra e só abre o
  # e-mail no fim de semana, sem deixar um link válido para sempre.
  CONFIRMATION_WINDOW = 2.days

  # Situação do anunciante. `inactive` é quem saiu por vontade própria;
  # `blocked` é quem a moderação tirou do ar. Os dois são barrados no login e
  # somem da vitrine junto com seus anúncios (ver Ad.published).
  STATUSES = { active: "active", inactive: "inactive", blocked: "blocked" }.freeze

  # A coluna se chama password_hash (dicionário de dados), mas has_secure_password
  # exige password_digest. O alias liga os dois sem coluna extra.
  alias_attribute :password_digest, :password_hash

  has_secure_password

  has_many :ads, dependent: :restrict_with_error
  has_many :sessions, dependent: :destroy
  # O vínculo com o provedor some junto com a conta; a conta no Google não.
  has_many :oauth_identities, dependent: :destroy
  # Proposta é preservada quando quem enviou some: o anunciante ainda precisa
  # do contato, que fica gravado na própria proposta.
  has_many :proposals, dependent: :nullify
  # Cobranças do plano Premium, uma por mês pago. Vão junto com a conta: são
  # histórico de pagamento dela, e o comprovante de verdade é o do PagBank.
  has_many :subscriptions, dependent: :destroy

  enum :status, STATUSES

  scope :confirmed, -> { where.not(confirmed_at: nil) }

  # Token sem coluna: o Rails assina o id junto com o valor do bloco. Como o
  # valor é o e-mail, trocar de e-mail invalida o link que ainda estava na caixa
  # de entrada do endereço antigo.
  generates_token_for :email_confirmation, expires_in: CONFIRMATION_WINDOW, &:email

  normalizes :email, with: ->(email) { email.to_s.strip.downcase }
  # O formulário aceita "(41) 98877-0011"; o wa.me precisa de "5541988770011".
  normalizes :phone, with: ->(phone) { normalize_phone(phone) }

  validates :name, presence: true
  validates :city, presence: true
  validates :state, presence: true, inclusion: { in: BRAZILIAN_STATES }
  validates :member_since, presence: true
  validates :email, presence: true, uniqueness: { case_sensitive: false },
                    format: { with: URI::MailTo::EMAIL_REGEXP }
  # Só dígitos com código do país: é o formato que o link do wa.me exige.
  validates :phone, presence: true, format: { with: /\A\d{12,13}\z/ }

  # 10 ou 11 dígitos são DDD + número, sem país. 12 ou 13 já vêm com o 55, então
  # o comprimento decide — e não o prefixo, que seria ambíguo com o DDD 55.
  def self.normalize_phone(phone)
    digits = phone.to_s.gsub(/\D/, "")

    digits.length.between?(10, 11) ? "55#{digits}" : digits
  end

  # Senha de quem entrou por Google ou Facebook: a coluna é NOT NULL e a pessoa
  # nunca digitou uma. É aleatória e não é dita a ninguém — quem quiser também
  # entrar com senha define uma no próprio perfil.
  def self.random_password
    SecureRandom.base58(32)
  end

  def confirmed?
    confirmed_at.present?
  end

  # Sem "!": não levanta exceção, devolve true. Idempotente de propósito, porque
  # clicar duas vezes no link do e-mail (o cliente que pré-carrega links faz isso
  # sozinho) não pode virar erro.
  def confirm_email
    return true if confirmed?

    update_column(:confirmed_at, Time.current)
  end

  def location
    "#{city}, #{state}"
  end

  # Até quando o Premium vale, ou nil para quem nunca pagou. É derivado das
  # cobranças e não guardado em users: uma coluna a mais seria uma segunda
  # verdade sobre a mesma coisa, e é `subscriptions.paid_through` que o
  # pagamento move — a mesma razão pela qual Ad.published olha User.active em
  # vez de copiar a situação para o anúncio.
  def premium_until
    subscriptions.paid.maximum(:paid_through)
  end

  # Tem Premium hoje? Consulta pelo escopo, para caber no índice
  # (user_id, paid_through) em vez de trazer a data para comparar em Ruby.
  def premium?
    subscriptions.current.exists?
  end
end
