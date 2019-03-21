class Debt < ApplicationRecord
  validates :user_id, :store_id, :nominal, :date_created, :finance_type, presence: true
  
  enum finance_type: { 
    ORDER:1,
    OTHER:2,
    BANK: 3
  }

  belongs_to :store
  belongs_to :user

  ORDER=1
  OTHER=2
  BANK=3
end
