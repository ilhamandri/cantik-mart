class User < ApplicationRecord
  include Clearance::User
  validates :level, :email, presence: true
  validates_uniqueness_of :email

  enum level: { 
                owner: 1,
                super_admin: 2,

                stock_admin: 3,
                cashier: 4,
                super_visi: 5,
                finance: 6,
                driver: 7,
                pramuniaga: 8
  }

  enum sex: {
    laki_laki: 0,
    perempuan: 1
  }

  belongs_to :store


  default_scope { order(created_at: :desc) }


  # KINDI / SYIFA
  OWNER = 'owner'
  # PARDEV
  SUPER_ADMIN = 'super_admin'
  # KEPALA GUDANG
  STOCK_ADMIN = 'stock_admin' 
  # KASIR
  CASHIER = 'cashier'
  # SUPER VISI TOKO
  SUPERVISI = 'super_visi'
  # KEUANGAN
  FINANCE = 'finance'

  PRAMUNIAGA = 'pramuniaga'

  DRIVER = 'driver'

  MALE = 'laki_laki'
  FEMALE = 'perempuan'

  has_many :transactions
  has_many :absents
  has_many :methods
  has_many :members
  has_many :notifications
  has_many :transfers
  has_many :invoice_transactions
  has_many :complains
  has_many :user_salaries

end
