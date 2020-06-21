class Opname < ApplicationRecord
  validates :user_id, :store_id, :file_name, presence: true

  belongs_to :store
  belongs_to :user
  
end
