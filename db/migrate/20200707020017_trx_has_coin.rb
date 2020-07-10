class TrxHasCoin < ActiveRecord::Migration[5.2]
  def change
  	add_column :transactions, :has_coin, :boolean, default: false, null: false
  end
end
