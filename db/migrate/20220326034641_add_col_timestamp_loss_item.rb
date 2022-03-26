class AddColTimestampLossItem < ActiveRecord::Migration[5.2]
  def change
    add_column :loss_items, :created_at, :datetime
    add_column :loss_items, :updated_at, :datetime
  end
end
