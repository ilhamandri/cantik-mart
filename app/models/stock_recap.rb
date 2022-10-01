class StockRecap < ApplicationRecord
  validates :date, :filename, presence: true
  
  default_scope { order(created_at: :desc) }
end