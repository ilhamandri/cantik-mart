class CreateUserController < ActiveRecord::Migration[5.2]
  def change
    create_table :user_methods do |t|
    	t.string :user_level, null: false
    	t.references :controller_method, null: false, foreign_key: true

    	t.timestamps
    end
  end
end
