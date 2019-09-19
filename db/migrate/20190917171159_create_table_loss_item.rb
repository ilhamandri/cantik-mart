class CreateTableLossItem < ActiveRecord::Migration[5.2]
  def change
    create_table :loss_items do |t|
    	t.references :item, foreign_key: true, null: false
    	t.references :loss, foreign_key: true, null: false
    	t.integer :quantity, null: false, default: 0
    	t.string :description, null: false, default: "-"
    end
  end
end
