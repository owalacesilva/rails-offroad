# Identidade de moderação, separada de User de propósito: quem modera não anuncia,
# e a concern de autenticação do anunciante não precisa saber que admin existe.
class Admin < ApplicationRecord
  alias_attribute :password_digest, :password_hash

  has_secure_password

  has_many :admin_sessions, dependent: :destroy
  # Anúncio avaliado sobrevive à saída do moderador; só perde a autoria.
  has_many :reviewed_ads, class_name: "Ad", foreign_key: :admin_id,
                          inverse_of: :admin, dependent: :nullify

  normalizes :email, with: ->(email) { email.to_s.strip.downcase }

  validates :name, presence: true
  validates :email, presence: true, uniqueness: { case_sensitive: false },
                    format: { with: URI::MailTo::EMAIL_REGEXP }
end
