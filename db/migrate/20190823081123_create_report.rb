class CreateReport < ActiveRecord::Migration[5.2]
  def change
    create_table :reports do |t|
    	t.references :store, foreign_key: true, null: false

  		t.bigint :cash, null: false, default: 0
  		t.bigint :stock_value, null: false, default: 0
    	t.bigint :receivable, null: false, default: 0
    	t.bigint :asset, null: false, default: 0

		  t.bigint :capital, null: false, default: 0
    	t.bigint :debt, null: false, default: 0
		  t.bigint :outcome, null: false, default: 0
		  t.bigint :sales, null: false, default: 0

      t.timestamps

    end
  end
end
