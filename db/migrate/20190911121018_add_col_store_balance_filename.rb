class AddColStoreBalanceFilename < ActiveRecord::Migration[5.2]
  def change
  	add_column :store_balances,:filename, :string
  end
end
