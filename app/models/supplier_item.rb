class SupplierItem < ApplicationRecord
  validates :item_id, :supplier_id, presence: true
  belongs_to :item
  belongs_to :supplier
  default_scope { order(created_at: :desc) }
end
