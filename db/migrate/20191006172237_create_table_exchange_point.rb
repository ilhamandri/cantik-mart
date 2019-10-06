class CreateTableExchangePoint < ActiveRecord::Migration[5.2]
  def change
    create_table :points do |t|
    	t.references :member, foreign_key: true, null: false
    	t.references :transaction, foreign_key: true
    	t.integer :point, null: false
    	t.integer :point_type, null: false
        t.references :exchange_point, foreign_key: true, null: false

        t.timestamps
    end
  end
end
