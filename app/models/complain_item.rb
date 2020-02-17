class ComplainItem < ApplicationRecord
  validates :item_id,:complain_id, :quantity, :description, presence: true
  belongs_to :item
  belongs_to :complain
end

