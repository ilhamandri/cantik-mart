class Receivable < ApplicationRecord
  validates :n_term, :nominal_term, :user_id, :store_id, :nominal, :date_created, :finance_type, presence: true
  
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
  default_scope { order(created_at: :desc) }
end
