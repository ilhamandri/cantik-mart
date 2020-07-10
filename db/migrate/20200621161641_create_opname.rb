class CreateOpname < ActiveRecord::Migration[5.2]
  def change
    create_table :opnames do |t|
    	t.timestamps
    	t.references :user, foreign_key: true, null: false
    	t.references :store, foreign_key: true, null: false
    	t.string :file_name, null: false
    end
  end
end
