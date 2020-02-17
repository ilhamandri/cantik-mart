class ChangeColItemTrxFloat < ActiveRecord::Migration[5.2]
  def change
  	change_column :transaction_items, :quantity, :float
  end
end
