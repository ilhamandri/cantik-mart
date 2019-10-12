class AddColNotes < ActiveRecord::Migration[5.2]
  def change
  	add_column :invoice_transactions, :description, :string, null: false, default: "-"
  end
end
