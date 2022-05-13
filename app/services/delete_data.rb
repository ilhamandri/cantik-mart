class DeleteData

	def self.deleteNotifications
		end_date = (DateTime.now-7.days).end_of_day
		notifications = Notification.where(read: 1).where("updated_at < ?", end_date)
		notifications.destroy_all if notifications.present?
	end

	def self.deleteTransaction start_date, store_id
		end_date = start_date.end_of_day
		trx_items = TransactionItem.where(store_id: store_id, created_at: start_date..end_date)
		puts "JUMLAH TRX ITEMS : " + trx_items.count.to_s
		trx_items.each do |trx_item|
			item = trx_item.item
			store = trx_item.store
			store_item = StoreItem.find_by(item: item, store: store)
			store_item.stock = store_item.stock + trx_item.quantity
			store_item.save!
		end
		trx_items.destroy_all
		puts "TRX ITEMS SUDAH DIHAPUS !"
		puts "-------------------------"
		trxs = Transaction.where(store_id: store_id, created_at: start_date..end_date)
		trxs.destroy_all
		puts "TRX SUDAH DIHAPUS !"
		puts "-------------------------"
		puts "STORE ID : " + store_id.to_s
		puts "TANGGAL : " + start_date.to_date.to_s
		puts "-------------------------"
	end

end