class AddColMemberCard < ActiveRecord::Migration[5.2]
  def change
  	add_column :transactions, :member_card, :bigint
  	add_column :complains, :member_card, :bigint
  end
end