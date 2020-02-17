class LossItem < ApplicationRecord
  validates :quantity, :item_id, :loss_id, :description, presence: true
  belongs_to :loss
  belongs_to :item
end
