class ChangeColItemTrx < ActiveRecord::Migration[5.2]
  def change
  	change_column :transaction_items, :quantity, :float
  	change_column :store_items, :stock, :float
  end
end
