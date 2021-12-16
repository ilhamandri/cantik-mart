class AddColTaxItem < ActiveRecord::Migration[5.2]
  def change
    add_column :items, :tax, :bigint, default: 0
    add_column :suppliers, :tax, :bigint, default: 0
    add_column :transactions, :tax, :bigint, default: 0
    add_column :orders, :tax, :bigint, default: 0
  end
end
