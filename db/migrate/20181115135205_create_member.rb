class CreateMember < ActiveRecord::Migration[5.2]
  def change
    create_table :members do |t|
      t.string :name, null: false
      t.string :id_card
      t.string :card_number, null: false
      t.string :phone, null: false
      t.integer :sex
      t.string :address
      t.references :user, foreign_key: true, null: false
      t.references :store, foreign_key: true, null: false

      t.timestamps
    end
  end
end
