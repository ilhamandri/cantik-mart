class OrderInv < ApplicationRecord
  validates :order_id, :date_paid, :nominal, presence: true
  belongs_to :order
  belongs_to :user
  default_scope { order(created_at: :desc) }
end
