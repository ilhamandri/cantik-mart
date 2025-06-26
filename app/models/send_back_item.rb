class SendBackItem < ApplicationRecord
  validates :item_id,:send_back_id, :quantity, :description, presence: true
  belongs_to :item
  belongs_to :send_back

  # enum feedback: {
  #   onprocess: 1,
  #   success: 2
  # }

  ONPROCESS = 'onprocess'
  SUCCESS = 'success'
end

