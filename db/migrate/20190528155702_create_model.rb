class CreateModel < ActiveRecord::Migration[5.2]
  def change
    create_table :controller_methods do |t|
    	t.references :controller, null: false, foreign_key: true
    	t.string :name, null: false

    	t.timestamps
    end
  end
end
