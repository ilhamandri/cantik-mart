class Capital < ApplicationRecord
  validates :user_id, :store_id, :nominal, :date_created, presence: true

  belongs_to :store
  belongs_to :user
  
end
