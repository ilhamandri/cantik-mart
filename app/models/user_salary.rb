class UserSalary < ApplicationRecord
  validates :user_id, :nominal, presence: true

  belongs_to :user
end

