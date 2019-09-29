class CreateTablePrint < ActiveRecord::Migration[5.2]
  def change
    create_table :prints do |t|
    	t.references :item, foreign_key: true, null: false
    	t.references :store, foreign_key: true, null: false
    	t.references :grocer_item, foreign_key: true
    	t.references :promotion, foreign_key: true
    	t.timestamps
    end
    add_column :items, :price_updated, :timestamp
  end
end
