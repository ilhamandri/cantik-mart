class StoreBalance < ApplicationRecord
  validates :store_id, presence: true
  belongs_to :store
end
