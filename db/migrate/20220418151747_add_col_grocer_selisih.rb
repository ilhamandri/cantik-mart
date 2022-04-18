class AddColGrocerSelisih < ActiveRecord::Migration[5.2]
  def change
    add_column :grocer_items, :selisih_pembulatan, :float, default: 0, null: false
    add_column :grocer_items, :ppn, :float, default: 0, null: false

  end
end
