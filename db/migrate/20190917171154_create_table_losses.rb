class CreateTableLosses < ActiveRecord::Migration[5.2]
  def change
    create_table :losses do |t|
    	t.references :user, foreign_key: true, null: false
    	t.references :store, foreign_key: true, null: false
    	t.integer :total_item, null: false
    	t.boolean :from_retur, default: false
    	t.bigint :ref_id
    	t.string :invoice, null: false
    	
    	t.timestamps
    end
  end
end
