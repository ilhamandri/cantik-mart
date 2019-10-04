class AddColTrxComp < ActiveRecord::Migration[5.2]
  def change
  	add_column :complains, :nominal, :bigint, default: 0, null: false
  	add_column :transactions, :sub_from_complain, :bigint, default: 0, null: false
  	add_column :transactions, :from_complain, :boolean, null: false, default: false
  	add_column :transactions, :complain_id, :bigint
  end
end
