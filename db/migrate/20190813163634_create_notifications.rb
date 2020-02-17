class CreateNotifications < ActiveRecord::Migration[5.2]
  def change
    create_table :notifications do |t|
        t.datetime :date_created, null: false
        t.integer :read, default: 0, null: false
        t.string :link, null: false
      	t.string :message, null: false
        t.integer :m_type, null: false, default: 1

  	    t.references :from_user, foreign_key: { to_table: :users}, null: false
  	    t.references :to_user, foreign_key: { to_table: :users }, null: false

        t.timestamps
    end
  end
end
