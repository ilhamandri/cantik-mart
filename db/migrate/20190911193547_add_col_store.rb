class AddColStore < ActiveRecord::Migration[5.2]
  def change
  	add_column :stores, :grand_total_before, :float, default: 0
  end
end
