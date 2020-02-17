class CreateTableOrderitem < ActiveRecord::Migration[5.2]
  def change
  	create_table :order_items do |t|
  		t.integer :receive
	  	t.bigint :quantity, null: false
	  	t.bigint :price, null: false
	  	t.references :item, foreign_key: true, null:false
	  	t.references :order, foreign_key: true, null:false
	  	t.string :description, default: "-"
	  	t.integer :new_receive, null: false, default: 0
	  	
	  	t.timestamps
  	end
  end
end
