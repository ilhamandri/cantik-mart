class CreateTablePoint < ActiveRecord::Migration[5.2]
  def change
    create_table :points do |t|
    	t.references :member, foreign_key: true, null: false
    	t.references :transaction, foreign_key: true
    	t.integer :point, null: false
    	t.integer :point_type, null: false

        t.timestamps
    end

    add_column :transactions, :point, :bigint, null: false, default: 0
    add_column :items, :sell_member, :bigint, null: false, default: 0
    add_column :grocer_items, :member, :boolean, null: false, default: false

  end
end
