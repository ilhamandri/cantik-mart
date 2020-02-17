class AddColStoreItem < ActiveRecord::Migration[5.2]
  def change
  	add_column :items, :local_item, :boolean, default: false
  	add_column :items, :margin, :integer, default: 0
  end
end
