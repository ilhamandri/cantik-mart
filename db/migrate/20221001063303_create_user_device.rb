class CreateUserDevice < ActiveRecord::Migration[5.2]
  def change
    create_table :user_devices do |t|
      t.string :device, null: false
      t.references :user, foreign_key: true, null: false
      t.string :ip, null: false
      t.string :action, null: false
      t.timestamps
    end
  end
end
