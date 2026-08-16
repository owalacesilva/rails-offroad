# Substitui o Active Storage: a URL do arquivo e a ordem são colunas, não
# metadados de blob.
class AdImage < ApplicationRecord
  belongs_to :ad

  validates :file_url, presence: true
  validates :sort_order, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  scope :ordered, -> { order(:sort_order, :created_at) }
end
