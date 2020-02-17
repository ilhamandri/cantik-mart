class ItemCat< ApplicationRecord
  validates :name, :department_id,  presence: true
  has_many :item
  belongs_to :department
end

