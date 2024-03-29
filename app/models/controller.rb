class Controller < ApplicationRecord
  validates :name, presence: true
  
  has_many :controller_methods
  default_scope { order(name: :asc) }
end

