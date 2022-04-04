class AddColPpnItem < ActiveRecord::Migration[5.2]
  def change
    add_column :items, :ppn, :float, default: 0, null: false
    add_column :items, :selisih_pembulatan, :float, default: 0, null: false
    add_column :transactions, :pembulatan, :float, default: 0, null: false
  end
end
