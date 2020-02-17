class AddColReceivable < ActiveRecord::Migration[5.2]
  def change
  	add_column :receivables, :n_term, :integer, null: false, default: 1
  	add_column :receivables, :nominal_term, :float, null: false, default: 0

  	add_column :debts, :n_term, :integer, null: false, default: 1
  	add_column :debts, :nominal_term, :float, null: false, default: 0

  end
end
