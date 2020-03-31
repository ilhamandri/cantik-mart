class AddTagUserSalary < ActiveRecord::Migration[5.2]
  def change
  	add_column :user_salaries, :tag, :string, null: false, default: ""
  	add_column :cash_flows, :tag, :string, null: false, default: ""
  end
end
