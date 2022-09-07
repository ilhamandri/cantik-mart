class CreateBackups < ActiveRecord::Migration[5.2]
  def change
    create_table :backups do |t|
      t.string :size, null: false
      t.string :filename, null: false
      t.datetime :created, null: false
      t.boolean :present, default: false
      t.timestamps
    end
  end
end
