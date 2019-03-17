class CreatePaidPayInv < ActiveRecord::Migration[5.2]
  def change
    create_table :invoice_transactions do |t|
    	t.string :invoice, null: false
    	t.integer :transaction_type, null: false, default: 1
    	t.string :transaction_invoice, null: false
    	t.integer :nominal, null: false, default: 0
    	t.timestamp :date_created, default: "CURRENT_TIMESTAMP"
    end
  end
end