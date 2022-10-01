class UserMethod < ApplicationRecord
  validates :user_level, :controller_method_id, presence: true
  
  belongs_to :controller_method
  default_scope { order(created_at: :desc) }
end

