class AddColStore < ActiveRecord::Migration[5.2]
  def change
  	add_column :stores, :grand_total_before, :bigint, default: 0
  	add_column :stores, :modals_before, :bigint, default: 0
  end
end
