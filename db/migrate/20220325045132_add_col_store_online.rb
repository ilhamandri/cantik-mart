class AddColStoreOnline < ActiveRecord::Migration[5.2]
  def change
    add_column :stores, :online_store, :boolean, default: false
  end
end
