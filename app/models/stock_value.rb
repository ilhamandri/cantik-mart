class StockValue < ApplicationRecord
  validates :user_id, :store_id, :nominal, :date_created, presence: true

  belongs_to :store
  belongs_to :user
  default_scope { order(created_at: :desc) }
  
end
