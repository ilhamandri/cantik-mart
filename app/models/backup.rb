class Backup < ApplicationRecord
  validates :filename, :size, :created, presence: true

  default_scope { order(created_at: :desc) }
end
