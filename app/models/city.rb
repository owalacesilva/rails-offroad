# Município brasileiro. Dado de referência do IBGE, não conteúdo de anunciante:
# a tabela nasce populada e ninguém a edita pelo portal (ver lib/brazilian_cities.rb).
#
# Nenhuma associação de propósito. `ads.city` e `users.city` seguem sendo texto
# livre — ligar as duas pontas é outra mudança, com migração de dados existentes.
class City < ApplicationRecord
  # A lista de UFs mora em User porque foi lá que nasceu; é a mesma whitelist
  # que a check constraint de cities.state repete no banco.
  validates :state, presence: true, inclusion: { in: User::BRAZILIAN_STATES }
  validates :name, presence: true, uniqueness: { scope: :state, case_sensitive: false }
  # Sete dígitos, o primeiro sendo o código da UF — nunca começa em zero.
  validates :ibge_code, presence: true, uniqueness: true, format: { with: /\A[1-9]\d{6}\z/ }

  scope :ordered, -> { order(:state, :name) }
  scope :by_state, ->(state) { where(state: state) }
  # A collation do MySQL é indiferente a caixa e a acento, então "sao paulo"
  # encontra "São Paulo" sem nenhuma coluna normalizada extra.
  scope :matching, ->(term) { where("cities.name LIKE ?", "#{sanitize_sql_like(term)}%") }

  def to_s
    name
  end

  def location
    "#{name}, #{state}"
  end
end
