class Receivable < ApplicationRecord
  validates :user_id, :store_id, :nominal, :date_created, :finance_type, presence: true
  
  enum finance_type: { 
    RETUR:1,
    OTHER:2,
    EMPLOYEE: 3,
    OVER: 4
  }

  belongs_to :store
  belongs_to :user

  RETUR=1
  OTHER=2
  EMPLOYEE=3
  OVER=4
end
