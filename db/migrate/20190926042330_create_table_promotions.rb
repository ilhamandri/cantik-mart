class CreateTablePromotions < ActiveRecord::Migration[5.2]
  def change
    create_table :promotions do |t|
      t.references :buy_item, foreign_key: { to_table: :items}, null: false
      t.integer :buy_quantity, null: false
      t.references :free_item, foreign_key: { to_table: :items }, null: false
      t.integer :free_quantity, null: false
      t.timestamp :start_promo, null: false
      t.timestamp :end_promo, null: false
      t.references :user, foreign_key: true, null: false
      t.string :promo_code, null: false
      t.integer :hit, null: false, default: 0
      
      t.timestamps
    end
  end
end
