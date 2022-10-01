class AddColEditedby < ActiveRecord::Migration[5.2]
  def change
    add_column :items, :edited_by, :bigint
    add_column :item_cats, :edited_by, :bigint
    add_column :departments, :edited_by, :bigint
    add_column :grocer_items, :edited_by, :bigint
    add_column :stores, :edited_by, :bigint
    add_column :store_items, :edited_by, :bigint
  end
end
