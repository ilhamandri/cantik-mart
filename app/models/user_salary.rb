class UserSalary < ApplicationRecord
  validates :user_id, :nominal, :checking, presence: true

  belongs_to :user
end

