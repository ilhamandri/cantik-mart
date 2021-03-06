class PopularItem < ApplicationRecord
  validates :item_id, :item_cat_id, :department_id, :store_id, :n_sell, :date, presence: true
  belongs_to :item
  belongs_to :item_cat
  belongs_to :department
  belongs_to :store
end
