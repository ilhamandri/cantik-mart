class AddColJpjph < ActiveRecord::Migration[5.2]
  def change
    add_column :user_salaries, :jp, :bigint, default: 0, null: false
    add_column :user_salaries, :jht, :bigint, default: 0, null: false
  end
end
