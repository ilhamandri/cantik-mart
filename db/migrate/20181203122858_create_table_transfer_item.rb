class CreateTableTransferItem < ActiveRecord::Migration[5.2]
  def change
    create_table :transfer_items do |t|
      t.references :transfer, foreign_key: true, null: false
      t.references :item, foreign_key: true, null: false
      t.integer :request_quantity, null: false, default: 1
      t.integer :sent_quantity, default: 0
      t.integer :receive_quantity, default: 0
      t.string :description, default: ''
      t.datetime :date_created

      t.timestamps
    end
  end
end
