class CreateStoreData < ActiveRecord::Migration[5.2]
  def change
    create_table :store_data do |t|
        t.references :store, foreign_key: true, null: false
        t.float :debt, null: false, default: 0
        t.float :receivable, null: false, default: 0
        t.float :tax, null: false, default: 0
        t.float :transaction_total, null: false, default: 0
        t.float :transaction_hpp, null: false, default: 0
        t.float :transaction_profit, null: false, default: 0
        t.float :transaction_tax, null: false, default: 0
        t.float :income, null: false, default: 0
        t.float :outcome, null: false, default: 0
        t.timestamp :date, null: false
        t.timestamps
    end
  end
end
