class Store < ApplicationRecord
  validates :name, :address, :phone, presence: true
  has_many :users
  has_many :store_items
  has_many :retur
  has_many :members
  has_many :complains
  has_many :transactions
  has_many :store_balances
  has_many :popular_items
  has_many :transaction_items
  has_many :not_popular_items
  has_many :store_datas
  has_many :loss_items
  
  enum store_type:{
    retail: 0,
    warehouse: 1
  }
  default_scope { order(created_at: :desc) }

  belongs_to :edited_by, class_name: "User", foreign_key: "edited_by", optional: true

end

