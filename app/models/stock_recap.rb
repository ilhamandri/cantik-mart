class StockRecap < ApplicationRecord
  validates :date, :filename, presence: true
  
end