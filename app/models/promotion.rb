class Promotion < ApplicationRecord
  validates :buy_item, :buy_quantity, :free_item, :free_quantity, :start_promo, :end_promo, presence: true
  belongs_to :buy_item, class_name: "Item", foreign_key: "buy_item_id", optional: true
  belongs_to :free_item, class_name: "Item", foreign_key: "free_item_id", optional: true

  belongs_to :user

  
end

