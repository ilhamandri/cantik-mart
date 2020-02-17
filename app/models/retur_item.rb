class ReturItem < ApplicationRecord
  validates :item_id,:retur_id, :quantity, :description, presence: true
  belongs_to :item
  belongs_to :retur

  enum feedback: {
    cash: 1,
    retur_item: 2,
    loss: 3
  }

  CASH = 'cash'
  RETUR_ITEM = 'retur_item'
  LOSS = 'loss'
end

