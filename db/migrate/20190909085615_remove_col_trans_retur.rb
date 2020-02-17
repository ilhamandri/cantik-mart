class RemoveColTransRetur < ActiveRecord::Migration[5.2]
  def change
  	remove_column :transactions, :member_id
	remove_column :complains, :member_id
  end
end
