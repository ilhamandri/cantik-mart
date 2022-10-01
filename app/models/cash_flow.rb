class CashFlow < ApplicationRecord
  validates :user_id, :store_id, :nominal, :finance_type, :date_created, :invoice, presence: true
  
  enum finance_type: { 
    Asset: 1,
    Debt: 2,
    Receivable: 3,
    Operational: 4,
    Fix_Cost: 5,
    Tax: 6,
    Transactions: 7,
    HPP: 8,
    Profit: 9,
    Outcome: 10,
    Income: 11,
    Employee_Loan: 12,
    Bank_Loan: 13,
    Supplier_Loan: 14,
    Modal: 15,
    Withdraw: 16,
    OtherLoan: 17,
    Send: 18,
    Receive: 19,
    Bonus: 20,
    WithdrawBank: 21,
    SendBank: 22
  }

  belongs_to :store
  belongs_to :user
  default_scope { order(created_at: :desc) }

  ASSET=1
  DEBT=2
  RECEIVABLE=3
  OPERATIONAL=4
  FIX_COST=5
  TAX=6
  TRANSACTIONS = 7
  HPP = 8
  PROFIT = 9
  OUTCOME = 10
  INCOME = 11
  EMPLOYEE_LOAN = 12
  BANK_LOAN = 13
  SUPPLIER_LOAN = 14
  MODAL = 15
  WITHDRAW = 16
  OTHERLOAN = 17
  SEND = 18
  RECEIVE = 19
  BONUS = 20
  WITHDRAW_BANK = 21
  SEND_BANK = 22

end