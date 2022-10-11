class AddColInvoiceTransaction < ActiveRecord::Migration[5.2]
  def change
    add_reference :invoice_transactions, :store, foreign_key: true
  end
end
