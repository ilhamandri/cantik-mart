class AddColToOrderItem < ActiveRecord::Migration[5.2]
  def change
	add_column :order_items, :last_buy, :float, null: false, default: 0
	add_column :order_items, :last_sell, :float, null: false, default: 0
  end
end
