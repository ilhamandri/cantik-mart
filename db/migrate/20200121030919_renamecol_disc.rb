class RenamecolDisc < ActiveRecord::Migration[5.2]
  def change
  	rename_column :discounts, :start, :start_date
  	rename_column :discounts, :end, :end_date
  end
end
