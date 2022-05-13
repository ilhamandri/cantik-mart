class AddColTrxQtyCoin < ActiveRecord::Migration[5.2]
  def change
    add_column :transactions, :quantity_coin, :bigint, default: 0, null: false
  end
end
