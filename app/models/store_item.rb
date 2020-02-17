class StoreItem < ApplicationRecord
  validates :stock, :store_id, :item_id, presence: true
  belongs_to :item
  belongs_to :store
end

