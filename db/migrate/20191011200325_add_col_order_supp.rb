class AddColOrderSupp < ActiveRecord::Migration[5.2]
  def change
  	add_reference :debts, :supplier, foreign_key: true
  end
end
