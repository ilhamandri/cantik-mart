class CreateDepartments < ActiveRecord::Migration[5.2]
  def change
    create_table :departments do |t|
    	t.string :name, null: false, default: "DEFAULT (NO DEPARTMENT)"
    	t.timestamps
    end
    add_reference :item_cats, :department, foreign_key: true
  end
end
