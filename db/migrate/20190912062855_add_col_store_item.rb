class AddColStoreItem < ActiveRecord::Migration[5.2]
  def change
  	add_column :items, :local_item, :boolean, default: false
  end
end
