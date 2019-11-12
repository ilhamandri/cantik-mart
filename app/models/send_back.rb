class SendBack < ApplicationRecord
	max_paginates_per 10
  	validates :total_items, :store_id, presence: true
  	has_many :send_back_items
  	belongs_to :store
  	belongs_to :user

  	belongs_to :received_by, class_name: "User", foreign_key: "received_by", optional: true
  
end

