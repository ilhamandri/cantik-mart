class AddColStoreInLossItem < ActiveRecord::Migration[5.2]
  def change
    add_reference :loss_items, :store, foreign_key: true
  end
end
