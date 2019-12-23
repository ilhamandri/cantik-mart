class CreatePredictItem < ActiveRecord::Migration[5.2]
  def change
    create_table :predict_items do |t|
    	t.references :buy, foreign_key: { to_table: :items}, null: false
  	    t.references :usually, foreign_key: { to_table: :items }, null: false
  	    t.float :percentage, null: false
  	    t.timestamps
    end
  end
end
