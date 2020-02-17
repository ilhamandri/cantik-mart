class InvoiceTransaction < ApplicationRecord
  validates :invoice, :date_created, :nominal, :transaction_invoice, :transaction_type, presence: true

  enum transaction_type: {
    PAID: 0,
    MINUS: 1
  }
  
  belongs_to :user
end

