class AddColTrx < ActiveRecord::Migration[5.2]
  def change
  	add_column :transactions, :card_number, :string
  end
end
