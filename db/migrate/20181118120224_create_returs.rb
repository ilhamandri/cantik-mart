class CreateReturs < ActiveRecord::Migration[5.2]
  def change
    create_table :returs do |t|
      t.string :invoice, null: false
      t.integer :total_items, null: false
      t.references :store, foreign_key: true, null: false
      t.references :supplier, foreign_key:true, null: false
      t.datetime :date_created, default: 'CURRENT_TIMESTAMP'
      t.datetime :date_picked, default: 'CURRENT_TIMESTAMP'
      t.datetime :date_approve, default: 'CURRENT_TIMESTAMP'
      t.datetime :status, default: 'CURRENT_TIMESTAMP'
      t.references :user, foreign_key: true, null: false
      t.bigint :picked_by
      t.bigint :approved_by

      t.timestamps
    end
  end
end
