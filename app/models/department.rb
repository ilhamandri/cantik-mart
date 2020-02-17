class Department< ApplicationRecord
  validates :name,  presence: true
  has_many :item_cat
end

