class CreateNotPopularItem < ActiveRecord::Migration[5.2]
  def change
    create_table :not_popular_items do |t|
    	t.date :date, null: false
    	t.references :item, foreign_key: true, null: false
    	t.references :item_cat, foreign_key: true, null: false
    	t.references :department, foreign_key: true, null: false
    	t.integer :n_sell, null: false, default: 1
    	
    	t.timestamps
    end
  end
end
