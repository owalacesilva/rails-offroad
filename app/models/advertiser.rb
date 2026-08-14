class Advertiser < ApplicationRecord
  BRAZILIAN_STATES = %w[
    AC AL AP AM BA CE DF ES GO MA MT MS MG PA PB PR PE PI RJ RN RS RO RR SC SP SE TO
  ].freeze

  has_secure_password

  has_many :listings, dependent: :restrict_with_error
  has_many :sessions, dependent: :destroy

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

  def location
    "#{city}, #{state}"
  end
end
