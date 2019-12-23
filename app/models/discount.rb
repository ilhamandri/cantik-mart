class Discount < ApplicationRecord
  validates :item_id,:start, :end, :discount, presence: true
  belongs_to :item
end

