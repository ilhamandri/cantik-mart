class AddColOrder < ActiveRecord::Migration[5.2]
  def change
  	add_column :orders, :salesman, :string, default: "-"
  	add_column :orders, :no_faktur, :string, default: "-"
  	add_column :orders, :discount, :integer, default: 0
  	add_column :orders, :discount_percentage, :bigint, default: 0
    add_column :orders, :from_retur, :boolean, default: false
    add_column :orders, :grand_total,  :bigint, default: 0

  	add_column :order_items, :discount_1,  :integer, default: 0
  	add_column :order_items, :discount_2,  :integer, default: 0
  	add_column :order_items, :ppn,  :integer, default: 0
    add_column :order_items, :grand_total,  :bigint, default: 0
	
  end
end
