class CreateTableItemPrice < ActiveRecord::Migration[5.2]
  def change
    create_table :item_prices do |t|
    	t.float :buy, null: false, default: 0
    	t.float :sell, null: false, default: 0
    	t.references :item, foreign_key: true, null: false
    	t.integer :month, null: false, default: 1
    	t.integer :year, null: false, default: 2015
    	t.timestamps
    end
  end
end
