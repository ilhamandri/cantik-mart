class ItemPrice < ApplicationRecord
	belongs_to :item
  default_scope { order(created_at: :desc) }
end