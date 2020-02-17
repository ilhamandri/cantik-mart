class CreateSendBackItem < ActiveRecord::Migration[5.2]
  def change
    create_table :send_back_items do |t|
    	  t.references :item, foreign_key: true, null: false
	      t.references :send_back, foreign_key: true, null: false
	      t.integer :quantity, null: false
	      t.integer :receive, null: false
	      t.string :description, null: false
	      
	      t.timestamps
	    end
  end
end
