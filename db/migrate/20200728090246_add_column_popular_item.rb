class AddColumnPopularItem < ActiveRecord::Migration[5.2]
  def change
  	add_reference :popular_items, :store, foreign_key: true
  end
end
