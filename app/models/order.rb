class Order < ApplicationRecord
  validates :invoice,:total_items, :total, :store_id, presence: true
  has_many :order_items
  has_many :order_inv
  belongs_to :store
  belongs_to :supplier
  belongs_to :user

  belongs_to :received_by, class_name: "User", foreign_key: "received_by", optional: true
  
end

