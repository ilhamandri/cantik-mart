class CreateTableCashFlow < ActiveRecord::Migration[5.2]
  def change
    create_table :cash_flows do |t|
    	t.references :user, foreign_key: true, null: false
    	t.references :store, foreign_key: true, null: false
    	t.bigint :nominal, null: false
    	t.integer :finance_type, null: false, default: 1
    	t.timestamp :date_created
		  t.string :description
      t.bigint :ref_id, null: true
      t.string :invoice, null: false, default: "-"

      t.timestamps
    end
  end
end
