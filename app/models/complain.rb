class Complain < ApplicationRecord

  include PgSearch::Model
  pg_search_scope :search_by_invoice, against: :invoice
    
  validates :total_items, :store_id, presence: true
  has_many :complain_items
  belongs_to :store
  belongs_to :user
  default_scope { order(created_at: :desc) }
end

