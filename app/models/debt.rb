class Debt < ApplicationRecord
  validates :n_term, :nominal_term, :user_id, :store_id, :nominal, :date_created, :finance_type, presence: true
  
  enum finance_type: { 
    ORDER:1,
    OTHER:2,
    BANK: 3,
    OTHERLOAN: 4
  }

  belongs_to :store
  belongs_to :user
  belongs_to :supplier, optional: true

  ORDER=1
  OTHER=2
  BANK=3
  OTHERLOAN=4
end
