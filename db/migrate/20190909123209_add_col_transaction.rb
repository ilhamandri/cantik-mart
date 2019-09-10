class AddColTransaction < ActiveRecord::Migration[5.2]
  def change
  	add_reference :transactions, :store, foreign_key: true, null: false, default: 1
  end
end
