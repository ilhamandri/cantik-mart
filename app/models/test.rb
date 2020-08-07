class Test < ApplicationRecord
	validates :name, presence: true

	belongs_to :store
	has_many :users
end