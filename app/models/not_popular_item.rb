class NotPopularItem < ApplicationRecord
  validates :item_id, :item_cat_id, :department_id, :n_sell, :date, :store_id, presence: true
  belongs_to :item
  belongs_to :item_cat
  belongs_to :department
  belongs_to :store
  default_scope { order(created_at: :desc) }
end
