class Transfer < ApplicationRecord
  validates :invoice, :from_store, :to_store,:date_created, presence: true
  belongs_to :from_store, class_name: "Store", foreign_key: "from_store_id", optional: true
  belongs_to :to_store, class_name: "Store", foreign_key: "to_store_id", optional: true
  has_many :transfer_items
  belongs_to :user

  belongs_to :picked_by, class_name: "User", foreign_key: "picked_by", optional: true
  belongs_to :approved_by, class_name: "User", foreign_key: "approved_by", optional: true
  belongs_to :confirmed_by, class_name: "User", foreign_key: "confirmed_by", optional: true

  
end

