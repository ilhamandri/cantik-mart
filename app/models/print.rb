class Print < ApplicationRecord
  validates :item_id,:store_id, presence: true
  belongs_to :item
  belongs_to :store

  belongs_to :grocer_item, optional: true
  belongs_to :promotion, optional: true
end

