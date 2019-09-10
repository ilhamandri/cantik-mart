class Member < ApplicationRecord
  validates :name, :address, :card_number, :id_card, :sex, :phone, presence: true

  enum sex: {
    laki_laki: 0,
    perempuan: 1
  }

  belongs_to :user
  belongs_to :store
end

