class Discount < ApplicationRecord
  validates :item_id,:start_date, :end_date, :discount, presence: true
  belongs_to :item
end

