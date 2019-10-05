class AddColMember < ActiveRecord::Migration[5.2]
  def change
  	add_column :members, :point, :bigint, null: false, default: 0
  end
end
