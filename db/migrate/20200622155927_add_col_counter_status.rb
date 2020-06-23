class AddColCounterStatus < ActiveRecord::Migration[5.2]
  def change
  	add_column :items, :counter, :bigint, default: 0
  end
end
