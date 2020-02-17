class CreateSupplier < ActiveRecord::Migration[5.2]
  def change
    create_table :suppliers do |t|
      t.string :name, null: false, default: "DEFAULT NAME SUPPLIER"
      t.string :address, null: false, default: "DEFAULT ADDRESS SUPPLIER"
      t.string :phone, null: false, default: 123456789
      t.integer :supplier_type, null: false, default: 0

      t.timestamps
    end
  end
end
