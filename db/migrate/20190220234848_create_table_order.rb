class CreateTableOrder < ActiveRecord::Migration[5.2]
  def change
  		create_table :orders do |t|
		  	t.string :invoice, null: false
		  	t.datetime :date_created, null: false
		  	t.datetime :date_receive
		  	t.references :supplier, foreign_key: true, null: false
		  	t.references :store, foreign_key: true, null: false
		  	t.integer :total_items, null: false
		  	t.bigint :total, null: false
		  	t.datetime :date_paid_off
		  	t.boolean :editable, null: false, default: true
		  	t.bigint :old_total, null: false, default: 0
		  	t.datetime :date_change
		  	t.references :user, foreign_key: true, null: false
		  	t.bigint :received_by

		  	t.timestamps
  		end
  end
end
