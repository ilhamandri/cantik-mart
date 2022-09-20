class AddColUserTempPass < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :temp_password, :string
  end
end
