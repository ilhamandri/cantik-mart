class Asset < ApplicationRecord
  validates :user_id, :store_id, :nominal, :date_created, :finance_type, presence: true
  
  enum finance_type: { 
    STORE:1,
    CAR:2
  }

  belongs_to :store
  belongs_to :user

  STORE=1
  CAR=2
  
end
