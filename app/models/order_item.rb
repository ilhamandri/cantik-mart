class OrderItem < ApplicationRecord
  validates :quantity, :item_id, :order_id, :price, presence: true
  belongs_to :order
  belongs_to :item
end
