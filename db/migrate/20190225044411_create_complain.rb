class CreateComplain < ActiveRecord::Migration[5.2]
  def change
    create_table :complains do |t|
    	t.string :invoice, null: false
	      t.integer :total_items, null: false
	      t.references :store, foreign_key: true, null: false
	      t.references :member, foreign_key:true
	      t.datetime :date_created, default: 'CURRENT_TIMESTAMP'
	      t.references :user, foreign_key: true

	      t.timestamps
    end
  end
end
