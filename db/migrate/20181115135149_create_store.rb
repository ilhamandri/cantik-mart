class CreateStore < ActiveRecord::Migration[5.2]
  def change
    create_table :stores do |t|
      t.string :name, null: false, default: "DEFAULT STORE NAME"
      t.string :address, null: false, default: "DEFAULT STORE ADDRESS"
      t.string :phone, null: false, default: 1234567
      t.integer :store_type, null: false, default: 1
      t.bigint :cash, null: false, default: 100000000
      t.bigint :equity, null: false, default: 100000000
      t.bigint :debt, null: false, default: 0
      t.bigint :receivable, null: false, default: 0

      t.timestamps
    end
    add_reference :users, :store, null: false
  end
end
