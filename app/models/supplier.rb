class Supplier < ApplicationRecord
  validates :name, :address, :phone, presence: true
  has_many :supplier_items
  has_many :returs
  has_many :orders
  has_many :debts
  
  enum supplier_type:{
    supplier: 0,
    warehouse: 1
  }
end
