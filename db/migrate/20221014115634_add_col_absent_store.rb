class AddColAbsentStore < ActiveRecord::Migration[5.2]
  def change
    add_reference :absents, :store, foreign_key: true
  end
end
