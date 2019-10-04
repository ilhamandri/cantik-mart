class CreateTableOrderinv < ActiveRecord::Migration[5.2]
  def change
  	create_table :order_invs do |t|
	  	t.string :invoice, null: false
	  	t.bigint :nominal, null: false
	  	t.references :order, foreign_key: true, null:false
	  	t.datetime :date_paid

	  	t.timestamps
	 end
  end
end
