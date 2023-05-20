class Absent < ApplicationRecord
  validates :user_id, presence: true
  belongs_to :user
  belongs_to :store, optional: true
end

