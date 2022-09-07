class Backup < ApplicationRecord
  validates :filename, :size, :created, presence: true

end
