class UserMethod < ApplicationRecord
  validates :user_level, :controller_method_id, presence: true
  
  belongs_to :controller_method
end

