class CreateStockRecaps < ActiveRecord::Migration[5.2]
  def change
    create_table :stock_recaps do |t|
      t.timestamp :date, null: false
      t.string :filename, null: false
      t.timestamps
    end
  end
end
