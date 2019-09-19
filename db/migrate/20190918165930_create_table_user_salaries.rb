class CreateTableUserSalaries < ActiveRecord::Migration[5.2]
  def change
    create_table :user_salaries do |t|
    	t.references :user, foreign_key: true, null: false
    	t.bigint :nominal, null: false, default: 0
    	t.integer :checking, null: false, default: 0
    	t.timestamps
    end
  end
end
