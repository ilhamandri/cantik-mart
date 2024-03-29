class Complain < ApplicationRecord
  validates :total_items, :store_id, presence: true
  has_many :complain_items
  belongs_to :store
  belongs_to :user
  default_scope { order(created_at: :desc) }
end

