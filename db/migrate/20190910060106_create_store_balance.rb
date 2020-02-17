class CreateStoreBalance < ActiveRecord::Migration[5.2]
  def change
    add_column :cash_flows, :payment, :string 
  end
end
