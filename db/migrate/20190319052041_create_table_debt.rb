class CreateTableDebt < ActiveRecord::Migration[5.2]
  def change
    create_table :debts do |t|
    	t.references :store, null: false, foreign_key: true
    	t.references :user, null: false, foreign_key: true
    	t.bigint :nominal, null: false
        t.bigint :deficiency, null: false
    	t.timestamp :date_created, null: false
    	t.string :description, null: false
    	t.integer :ref_id, null: true
    	t.integer :finance_type, null: false
        t.datetime :due_date, null: false

        t.timestamps
    end
  end
end
