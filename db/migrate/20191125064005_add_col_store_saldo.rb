class AddColStoreSaldo < ActiveRecord::Migration[5.2]
  def change
  	add_column :stores, :bank, :bigint, null: false, default: 0
  	add_column :stores, :grand_total_card_before, :bigint, null: false, default: 0
	  add_column :store_balances, :bank, :bigint, null: false, default: 0
  	
  end
end
