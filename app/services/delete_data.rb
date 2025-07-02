class DeleteData

	def self.clean_data
		start_date = DateTime.now.beginning_of_year - 10.years
		end_date = ((DateTime.now.beginning_of_year - 3.years) - 1.day).end_of_day
		
		deleteNotifications
		deleteOrder start_date, end_date
		deleteTransaction start_date, end_date
		deleteTransfer start_date, end_date
		deleteRetur start_date, end_date
		deleteSendBack start_date, end_date
		deleteActivityLog start_date, end_date

		puts "DATA CLEAN UP SUCCESS !!"
	end

	def self.deleteNotifications
		end_date = (DateTime.now-7.days).end_of_day
		notifications = Notification.where(read: 1).where("updated_at < ?", end_date)
		notifications.destroy_all
	end

	def self.deleteOrder start_date, end_date
		order_items = OrderItem.where(created_at: start_date..end_date).destroy_all
		order_invoice = OrderInv.where(created_at: start_date..end_date).destroy_all
		order = Order.where(created_at: start_date..end_date).destroy_all
	end

	def self.deleteTransaction start_date, end_date
		trx_items = TransactionItem.where(created_at: start_date..end_date).destroy_all
		trx = Transaction.where(created_at: start_date..end_date).destroy_all
	end

	def self.deleteTransfer start_date, end_date
		trf_items = TransferItem.where(created_at: start_date..end_date).destroy_all
		trf = Transfer.where(created_at: start_date..end_date).destroy_all
	end

	def self.deleteRetur start_date, end_date
		retur_items = ReturItem.where(created_at: start_date..end_date).destroy_all
		retur = Retur.where(created_at: start_date..end_date).destroy_all
	end

	def self.deleteSendBack start_date, end_date
		send_back_items = SendBackItem.where(created_at: start_date..end_date).destroy_all
		send_back = SendBack.where(created_at: start_date..end_date).destroy_all
	end

	def self.deleteActivityLog start_date, end_date
		activity = PublicActivity::Activity.where(created_at: start_date..end_date).destroy_all
	end

	# DeleteData.deleteTransaction (DateTime.now.beginning_of_day-1.day), 2
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

	def self.delete_items
		files = Dir["./data/backup/delete/*.xlsx"]
		files.each do |file|
			xlsx = Roo::Spreadsheet.open(file, extension: :xlsx)
			xlsx.each_with_index do |row, idx|
				code = row[0]
				item = Item.find_by(code: code)
				next if item.nil?
				trx_items = item.transaction_items
				transfer_items = item.transfer_items
				order_items = item.order_items
				send_back_items = item.send_back_items
				if send_back_items.empty? && trx_items.empty? && transfer_items.empty? && order_items.empty? 
					item.store_items.destroy_all
					item.item_prices.destroy_all 
					item.destroy
				end
	 		end
	 	end
	end

	
end