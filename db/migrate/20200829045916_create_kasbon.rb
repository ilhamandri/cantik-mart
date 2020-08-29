class CreateKasbon < ActiveRecord::Migration[5.2]
  def change
    create_table :kasbons do |t|
    	t.references :user, foreign_key: true, null: false
    	t.bigint :nominal, null: false
    	t.timestamps
    end
  end
end
