class StoreBalance < ApplicationRecord
  validates :store_id, presence: true
  belongs_to :store
  default_scope { order(created_at: :desc) }
end
