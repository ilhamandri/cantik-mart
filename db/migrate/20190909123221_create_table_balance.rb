class CreateTableBalance < ActiveRecord::Migration[5.2]
  def change
    create_table :store_balances do |t|
    	t.float :cash, null: false
    	t.float :receivable, null: false
    	t.float :stock_value, null: false
    	t.float :asset_value, null: false
    	t.float :equity, null: false
    	t.float :debt, null: false
    	t.float :transaction_value, null: false
    	t.float :outcome, null: false
        t.references :store, foreign_key: true, null: false
        t.timestamps
    end
  end
end
