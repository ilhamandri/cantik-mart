class Member < ApplicationRecord
  validates :name, :address, :card_number, :sex, :phone, presence: true

  enum sex: {
    laki_laki: 0,
    perempuan: 1
  }

  belongs_to :user
  belongs_to :store
  has_many :points
end

