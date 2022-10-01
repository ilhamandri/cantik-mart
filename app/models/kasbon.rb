class Kasbon< ApplicationRecord
  validates :user_id, :nominal,  presence: true
  belongs_to :user
  default_scope { order(created_at: :desc) }
end

