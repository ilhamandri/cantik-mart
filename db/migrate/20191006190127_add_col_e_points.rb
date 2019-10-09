class AddColEPoints < ActiveRecord::Migration[5.2]
  def change
  	create_table :vouchers do |t|
  		t.references :exchange_point, foreign_key: true, null: false
  		t.bigint :voucher_code, null: false

      t.timestamps
  	end
  	add_column :exchange_points,:status, :boolean, null: false, default: true
  	add_reference :points, :voucher, foreign_key: true
  	add_reference :transactions, :voucher, foreign_key: true
    add_column :grocer_items, :member_price, :bigint, default: 0
  end
end
