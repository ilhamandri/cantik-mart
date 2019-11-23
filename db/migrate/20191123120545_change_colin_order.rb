class ChangeColinOrder < ActiveRecord::Migration[5.2]
  def change
  	change_column :orders, :discount_percentage, :float
  	change_column :order_items, :ppn, :float
  end
end
