# Conta de um provedor externo ligada a um anunciante.
#
# Guarda só o vínculo: o `uid` é o identificador que o provedor dá à pessoa e
# nunca muda, enquanto o e-mail dela pode mudar. É por isso que o login procura
# primeiro pelo par (provider, uid) e só depois pelo e-mail.
#
# Nenhum token é gravado. O portal não age em nome de ninguém no Google nem no
# Facebook — usa o provedor uma vez, para saber quem é quem, e descarta o
# access_token no fim da requisição.
class OauthIdentity < ApplicationRecord
  PROVIDERS = %w[google facebook].freeze

  belongs_to :user

  validates :provider, presence: true, inclusion: { in: PROVIDERS }
  validates :uid, presence: true, uniqueness: { scope: :provider, case_sensitive: false }
end
