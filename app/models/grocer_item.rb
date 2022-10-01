class GrocerItem< ApplicationRecord
  validates :min, :max, :price,  presence: true
  belongs_to :item
  default_scope { order(created_at: :desc) }
end

