class CreateDiscount < ActiveRecord::Migration[5.2]
  def change
    create_table :discounts do |t|
        t.string :code, null: false
    	t.date :start, null: false
    	t.date :end, null: false
    	t.integer :discount, null: false
    	t.references :item, null: false, foreign_key: true
    	t.boolean :status, null: false, default: false
    	t.timestamps
    end
  end
end
