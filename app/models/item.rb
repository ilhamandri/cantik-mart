class Item < ApplicationRecord
  include PgSearch::Model

  pg_search_scope :search_by_code, against: [:code]
  
  pg_search_scope :search_by_name, lambda { |name_part, query|
    raise ArgumentError unless [:name].include?(name_part)
    {
      against: name_part,
      query: query.to_s
    }
  }

  pg_search_scope :search_by_code_s, lambda { |name_part, query|
    raise ArgumentError unless [:code].include?(name_part)
    {
      against: name_part,
      query: query.to_s
    }
  }

  pg_search_scope :item_search, associated_against: {
    cheeses: [:kind, :brand],
    cracker: :kind
  }

  validates :item_cat_id, :name, :code, presence: true
  belongs_to :item_cat
  has_many :store_items
  has_many :retur_items
  has_many :order_items
  has_many :transaction_items
  has_many :grocer_items
  has_many :supplier_items
  has_many :item_prices
  has_many :transfer_items
  has_many :send_back_items
  has_many :popular_items
  has_many :not_popular_items
  has_many :loss_items

  belongs_to :edited_by, class_name: "User", foreign_key: "edited_by", optional: true

end

