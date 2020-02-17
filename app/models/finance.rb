class Finance < ApplicationRecord
  validates :user_id, :store_id, :nominal, :finance_type, :date_created, presence: true
  
  enum finance_type: { 
    AKTIFA:1,
    PASSIVE:2
  }

  belongs_to :store
  belongs_to :user

  AKTIFA=1
  PASSIVA=2
  
end
