class AddColumnNotPopularItem < ActiveRecord::Migration[5.2]
  def change
  	add_reference :not_popular_items, :store, foreign_key: true
  end
end
