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
    Withdraw: 16
  }

  belongs_to :store
  belongs_to :user

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

end