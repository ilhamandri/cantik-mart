class GrocerItem< ApplicationRecord
  validates :min, :max, :price,  presence: true
  belongs_to :item
end

