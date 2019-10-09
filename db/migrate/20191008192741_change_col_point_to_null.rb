class ChangeColPointToNull < ActiveRecord::Migration[5.2]
  def change
  	change_column_null :points, :exchange_point_id, true
  end
end
