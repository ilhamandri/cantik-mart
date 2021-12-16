class Transaction < ApplicationRecord
  validates :invoice,:items, :total, :user_id, :grand_total, :payment_type,  presence: true
  has_many :transaction_items
  belongs_to :user
  belongs_to :store
  belongs_to :complain, optional: true

  enum payment_type:{
  	CASH: 1,
  	DEBIT: 2,
  	CREDIT: 3,
    QRIS: 4
  }

  enum bank:{
  	BCA: 1,
  	MANDIRI: 2,
  	BNI: 3,
  	BRI: 4,
  	PERMATA: 5
  }
end

