class Notification < ApplicationRecord
  validates :from_user, :to_user, :message, :link,:date_created, presence: true
  belongs_to :to_user, class_name: "User", foreign_key: "to_user_id", optional: true
  belongs_to :from_user, class_name: "User", foreign_key: "from_user_id", optional: true

  enum m_type: { 
    primary: 1,
    warning: 2,
    danger: 3,
    success: 4,
    info: 5
  }

	PRIMARY = 'primary'
	WARNING = 'warning'
	DANGER = 'danger'
	SUCCESS = 'success'
	INFO = 'info'

end

