class CreateJmItems < ActiveRecord::Migration[5.2]
  def change
    create_table :jm_items do |t|
      t.string :code, null: false, default: 'DEFAULT_CODE'
      t.string :name, null: false, default: 'DEFAULT_NAME'
      t.bigint :sell, null: false, default: 0      
      t.timestamps
    end
  end
end
