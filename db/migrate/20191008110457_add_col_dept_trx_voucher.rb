class AddColDeptTrxVoucher < ActiveRecord::Migration[5.2]
  def change
  	add_column :item_cats, :use_in_point, :boolean, null: false, default: true
  	add_column :transactions, :voucher, :bigint
  	add_column :vouchers, :used, :timestamp
  	add_column :members, :point, :bigint
  end
end
