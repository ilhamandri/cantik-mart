class Department< ApplicationRecord
  validates :name,  presence: true
  has_many :item_cat
  default_scope { order(created_at: :desc) }
end

