class Voucher < ApplicationRecord
  validates :exchange_point_id, :voucher_code, presence: true

  belongs_to :exchange_point
  
end
