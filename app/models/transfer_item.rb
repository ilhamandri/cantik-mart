class TransferItem < ApplicationRecord
  validates :item_id,:transfer_id, :request_quantity, presence: true
  belongs_to :item
  belongs_to :transfer
  default_scope { order(created_at: :desc) }
end

