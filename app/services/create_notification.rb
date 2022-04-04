class CreateNotification
	def self.new_price
		Item.where("tax > 0").each do |item|
			Store.all.each do |store|
	          Print.create item: item, store: store
	        end
	        message = "Terdapat perubahan harga jual. Segera cetak label harga "+item.name
	        to_users = User.where(level: ["owner", "super_admin", "super_visi"])
	        to_users.each do |to_user|
	        	Notification.create from_user: User.last, to_user: to_user, m_type: "info", message: message, link: "/prints", date_created: DateTime.now
	        end
	    end
	end
end