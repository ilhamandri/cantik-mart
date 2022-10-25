class StoreItem < ApplicationRecord
  validates :stock, :store_id, :item_id, presence: true
  belongs_to :item
  belongs_to :store

  belongs_to :edited_by, class_name: "User", foreign_key: "edited_by", optional: true

end

