class CreateItemPrice < ActiveRecord::Migration[5.2]
  def change
    create_table :item_prices do |t|
    	t.references :item, foreign_key:  true, null: false
    	t.integer :month, null: false
    	t.integer :year, null: false
    	t.float :price, null: false

    	t.timestamps
    end
  end
end
