class GrocerItem< ApplicationRecord
  validates :min, :max, :price,  presence: true
  belongs_to :item
  default_scope { order(min: :asc) }
  belongs_to :edited_by, class_name: "User", foreign_key: "edited_by", optional: true

end

