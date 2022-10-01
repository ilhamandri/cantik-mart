class ExchangePoint < ApplicationRecord
  validates :point, :name, presence: true
  
  has_many :points
  default_scope { order(created_at: :desc) }
end
