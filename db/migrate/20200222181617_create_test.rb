class CreateTest < ActiveRecord::Migration[5.2]
  def change
    create_table :tests do |t|
    	t.string :name
    	t.references :store, foreign_key: true, null: false

    	t.timestamps
    end
  end
end
