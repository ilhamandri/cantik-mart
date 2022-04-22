class AddColTrxItem < ActiveRecord::Migration[5.2]
  def change
    add_column :transaction_items, :ppn, :float, default: 0, null: false
    add_reference :transaction_items, :supplier, foreign_key: true
    add_reference :transaction_items, :store, foreign_key: true
    add_column :transaction_items, :profit, :float, default: 0, null: false
    add_column :transaction_items, :total, :float, default: 0, null: false

  end
end
