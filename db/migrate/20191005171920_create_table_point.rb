class CreateTablePoint < ActiveRecord::Migration[5.2]
  def change
    create_table :exchange_points do |t|
        t.integer :point, null: false
        t.string :name, null: false
        t.bigint :hit, null: false, default: 0
        t.integer :quantity, null: false

        t.timestamps
    end

    add_column :transactions, :point, :bigint, null: false, default: 0
    add_column :items, :sell_member, :bigint, null: false, default: 0
    add_column :grocer_items, :member, :boolean, null: false, default: false

  end
end
