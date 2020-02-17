class ProfitLoss < ApplicationRecord
  validates :user_id, :store_id, :nominal, :date_created, :finance_type, presence: true

  belongs_to :store
  belongs_to :user
  
  enum finance_type:{
    Profit: 1,
    Loss: 2
  }

  PROFIT=1
  LOSS=2
end
