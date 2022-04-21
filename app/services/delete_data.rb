class DeleteData

	def self.deleteNotifications
		end_date = (DateTime.now-7.days).end_of_day
		notifications = Notification.where(read: 1).where("updated_at < ?", end_date)
		notifications.destroy_all if notifications.present?
	end

end