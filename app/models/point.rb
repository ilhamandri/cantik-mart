class Point < ApplicationRecord
  validates :point, :member_id, presence: true
  
  belongs_to :trx, class_name: "Transaction", foreign_key: "transaction_id", optional: true
  belongs_to :member
  belongs_to :exchange_point
  belongs_to :voucher, optional: true

  enum point_type: {
    get: 0,
    exchange: 1
  }

  GET = "get"
  EXCHANGE = "exchange"

end
