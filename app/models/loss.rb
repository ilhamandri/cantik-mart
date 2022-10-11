class Loss < ApplicationRecord
  validates :user_id, :store_id, :total_item, presence: true

  belongs_to :store
  belongs_to :user
  has_many :loss_items
  
end
