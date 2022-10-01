class ControllerMethod < ApplicationRecord
  validates :name, presence: true
  
  belongs_to :controller
  has_many :user_methods
  default_scope { order(name: :asc) }
end

