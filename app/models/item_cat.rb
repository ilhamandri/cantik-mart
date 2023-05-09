class ItemCat< ApplicationRecord
  validates :name, :department_id,  presence: true
  has_many :item
  belongs_to :department
  default_scope { order(name: :asc) }
  belongs_to :edited_by, class_name: "User", foreign_key: "edited_by", optional: true

end

