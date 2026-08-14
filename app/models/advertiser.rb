class Advertiser < ApplicationRecord
  has_many :listings, dependent: :restrict_with_error

  validates :name, presence: true
  validates :city, presence: true
  validates :state, presence: true, length: { is: 2 }
  validates :member_since, presence: true
  validates :email, presence: true, uniqueness: { case_sensitive: false },
                    format: { with: URI::MailTo::EMAIL_REGEXP }
  # Só dígitos com código do país: é o formato que o link do wa.me exige.
  validates :phone, presence: true, format: { with: /\A\d{12,13}\z/ }

  def location
    "#{city}, #{state}"
  end
end
