class AddColTrxCoin < ActiveRecord::Migration[5.2]
  def change
    add_column :transactions, :tax_coin, :float, default: 0, null: false
  end
end
