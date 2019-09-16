class CreateItem < ActiveRecord::Migration[5.2]
  def change
    create_table :items do |t|
      t.string :code, null: false, default: 'DEFAULT_CODE'
      t.string :name, null: false, default: 'DEFAULT_NAME'
      t.integer :stock, null: false, default: 0
      t.integer :buy, null: false, default: 0
      t.integer :sell, null: false, default: 0
      t.references :item_cat, null: false, foreign_key: true
      t.string :brand, null: false, defautl: "DEFAULT BRAND"
      t.float :wholesale, null: false, default: 0
      t.float :box, null: false, default: 0
      t.string :image
      t.float :buy_grocer, default: 0
      t.float :discount, null: false, default: 0
      
      t.timestamps
    end
  end
end
