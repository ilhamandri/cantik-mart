class CreateComplainItem < ActiveRecord::Migration[5.2]
  def change
    create_table :complain_items do |t|
    	  t.references :item, foreign_key: true, null: false
	      t.references :complain, foreign_key: true, null: false
	      t.integer :quantity, null: false
	      t.string :description, null: false
	      
	      t.timestamps
    end
  end
end
