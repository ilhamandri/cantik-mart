class CreateTableBalance < ActiveRecord::Migration[5.2]
  def change
    create_table :store_balances do |t|
    	t.bigint :cash, null: false
    	t.bigint :receivable, null: false
    	t.bigint :stock_value, null: false
    	t.bigint :asset_value, null: false
    	t.bigint :equity, null: false
    	t.bigint :debt, null: false
    	t.bigint :transaction_value, null: false
    	t.bigint :outcome, null: false
        t.references :store, foreign_key: true, null: false
        t.timestamps
    end
  end
end
