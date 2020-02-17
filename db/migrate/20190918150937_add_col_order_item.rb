class AddColOrderItem < ActiveRecord::Migration[5.2]
  def change
  	add_column :order_items, :total, :bigint, null: false, default: 0
  end
end
