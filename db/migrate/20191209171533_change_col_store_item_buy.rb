class ChangeColStoreItemBuy < ActiveRecord::Migration[5.2]
  def change
  	change_column :store_items, :buy, :float
  	change_column :store_items, :head_buy, :float
  end
end
