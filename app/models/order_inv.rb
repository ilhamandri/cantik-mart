class OrderInv < ApplicationRecord
  validates :order_id, :date_paid, :nominal, presence: true
  belongs_to :order
end
