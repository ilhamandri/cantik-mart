class ChangeColItemMargin < ActiveRecord::Migration[5.2]
  def change
    change_column :items, :margin, :float
  end
end
