class AddColItemAverage < ActiveRecord::Migration[5.2]
  def change
  	add_column :store_items, :limit, :bigint, default: 5
  	add_column :store_items, :ideal_stock, :bigint, default: 10
  	add_column :items, :kpi, :bigint, default: 0
  end
end
