class Retur < ApplicationRecord

  	include PgSearch::Model
  	pg_search_scope :search_by_invoice, against: :invoice

	max_paginates_per 10
  	validates :total_items, :store_id, presence: true
  	has_many :retur_items
  	belongs_to :store
  	belongs_to :supplier
  	belongs_to :user

  	belongs_to :picked_by, class_name: "User", foreign_key: "picked_by", optional: true
  	belongs_to :approved_by, class_name: "User", foreign_key: "approved_by", optional: true
  	belongs_to :confirmed_by, class_name: "User", foreign_key: "approved_by", optional: true
  
end

