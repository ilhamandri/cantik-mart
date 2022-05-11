class AddColTrxGtCoin < ActiveRecord::Migration[5.2]
  def change
    add_column :transactions, :grand_total_coin, :float, default: 0, null: false
    add_column :transactions, :hpp_total_coin, :float, default: 0, null: false
    add_column :transactions, :profit_coin, :float, default: 0, null: false
  end
end
