class ExchangePoint < ApplicationRecord
  validates :point, :name, presence: true
  
  has_many :points
end
