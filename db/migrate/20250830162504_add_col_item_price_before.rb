class AddColItemPriceBefore < ActiveRecord::Migration[7.2]
  def change
    add_column :items, :price_before, :float, default: 0
  end
end
