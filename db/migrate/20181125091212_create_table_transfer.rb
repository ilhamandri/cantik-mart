class CreateTableTransfer < ActiveRecord::Migration[5.2]
  def change
    create_table :transfers do |t|
      t.string :invoice, null:false
      t.datetime :date_created, null:false
      t.datetime :date_approve
      t.datetime :date_picked
      t.datetime :date_confirm
      t.datetime :status
      t.integer :total_items
      t.references :from_store, foreign_key: { to_table: :stores}, null: false
      t.references :to_store, foreign_key: { to_table: :stores }, null: false
      t.string :description, null: false, default: "-"
      t.references :user, foreign_key: true, null: false
      t.bigint :approved_by
      t.bigint :picked_by
      t.bigint :confirmed_by
      
      t.timestamps
    end
  end
end
