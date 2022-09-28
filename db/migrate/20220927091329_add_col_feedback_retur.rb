class AddColFeedbackRetur < ActiveRecord::Migration[5.2]
  def change
    add_column :returs, :date_confirm, :datetime
    add_column :returs, :confirmed_by, :bigint
  end
end
