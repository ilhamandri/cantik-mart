class AddColEPoints < ActiveRecord::Migration[5.2]
  def change
  	add_column :exchange_points,:status, :boolean, null: false, default: true
  end
end
