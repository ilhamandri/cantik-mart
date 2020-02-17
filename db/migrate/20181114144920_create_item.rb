class CreateItem < ActiveRecord::Migration[5.2]
  def change
    create_table :items do |t|
      t.string :code, null: false, default: 'DEFAULT_CODE'
      t.string :name, null: false, default: 'DEFAULT_NAME'
      t.bigint :stock, null: false, default: 0
      t.float :buy, null: false, default: 0
      t.bigint :sell, null: false, default: 0
      t.references :item_cat, null: false, foreign_key: true
      t.string :brand, null: false, defautl: "DEFAULT BRAND"
      t.bigint :wholesale, null: false, default: 0
      t.bigint :box, null: false, default: 0
      t.string :image
      t.bigint :buy_grocer, default: 0
      t.bigint :discount, null: false, default: 0
      
      t.timestamps
    end
  end
end
