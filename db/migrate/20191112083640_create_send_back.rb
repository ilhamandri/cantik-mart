class CreateSendBack < ActiveRecord::Migration[5.2]
  def change
    create_table :send_backs do |t|
    	t.string :invoice, null: false
      	t.integer :total_items, null: false
      	t.references :store, foreign_key: true, null: false
      	t.datetime :date_receive, default: 'CURRENT_TIMESTAMP'
      	t.references :user, foreign_key: true, null: false
      	t.bigint :received_by

      	t.timestamps
    end
  end
end
