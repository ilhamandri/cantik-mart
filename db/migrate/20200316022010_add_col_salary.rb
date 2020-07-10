class AddColSalary < ActiveRecord::Migration[5.2]
  def change
  	add_column :user_salaries, :bonus, :bigint, null: false, default: 0
  	add_column :user_salaries, :pay_receivable, :bigint, null: false, default: 0
  	add_column :user_salaries, :pay_kasbon, :bigint, null: false, default: 0
  end
end
