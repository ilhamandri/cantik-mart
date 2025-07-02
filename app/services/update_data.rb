class UpdateData

	def self.updateSupplierHandlingLocal
		Supplier.all.each do |supplier|
			supplier_items = supplier.supplier_items
			next if !supplier_items.present?
			item = supplier_items.first.item
			supplier.local = true if item.local_item
			supplier.save!
		end
	end

	def self.delete_unused_notification
    	Notification.where("date_created < ?", DateTime.now - 10.days).destroy_all
    	Notification.where(to_user: User.where(active: false)).destroy_all
    	Notification.where(from_user: User.where(active: false)).destroy_all

	end

	# UpdateData.UpdateDataTransactionItemTotal start_date, end_date
	def self.UpdateDataTransactionItemTotal start_date, end_date
		trx_items = TransactionItem.where(total: 0, created_at: start_date..end_date).where.not(item_id: [29670, 29671, 29672], price: 0)
		trx_items.each do |trx_item|
			trx_item.store_id = trx_item.trx.store_id
			supplier_items = SupplierItem.where(item: trx_item.item)
			trx_item.supplier_id = supplier_items.first.supplier.id if supplier_items.present?

			sell = trx_item.price-trx_item.discount
			qty = trx_item.quantity

			trx_item.total = sell * qty
			ppn = sell-(sell/(1+(trx_item.item.tax.to_f/100.0)))
			trx_item.ppn = ppn*qty
			trx_item.profit = (sell-ppn-trx_item.item.buy)*qty

			trx_item.save!
		end
	end

	# UpdateData.updatePopularItems
	def self.updatePopularItems store_id, department_id, start_date
		start_date =  DateTime.now.beginning_of_month - 1.month if start_date.nil?
		end_date = start_date.end_of_month
	    item_sells = TransactionItem.where(item: Item.where(item_cat: Department.find_by(id: department_id).item_cat), created_at: start_date..end_date).group(:item_id).count
	    high_results = Hash[item_sells.sort_by{|k, v| v}.reverse]
	    highs = high_results
	    curr_date_pop_item = PopularItem.where("date = ?", DateTime.now.beginning_of_month)
	    curr_date_pop_item.destroy_all if curr_date_pop_item.present?
	    date = start_date
	    highs.each_with_index do |data, idx|
	    	break if idx == 100
		    item = Item.find_by(id: data[0])
		    item_cat = item.item_cat
		    department = item_cat.department
		    sell = data[1]
		    pop_item = PopularItem.create item: item, item_cat: item_cat, department: department, n_sell: sell, date: date, store_id: store_id
	    end
	end

	def self.updateAllPopularItems store_id, start_date
		
	end

	# UpdateData.updateStoreLossItem
	def self.updateStoreLossItem
		Loss.all.each do |loss|
			loss.loss_items.update_all(store_id: loss.store.id)
		end
	end

	# UpdateData.updateStoreItem
	def self.updateStoreItem
		ids = []
		Store.all.each do |store|
			duplicates = StoreItem.where(store: store).select(:item_id).group(:item_id).having("count(*) > 1").size
			duplicates.each do |item_id|
				store_items = StoreItem.where(store: store, item_id: item_id).order("updated_at ASC").pluck(:id)
				store_items.pop
				ids += store_items
				StoreItem.where(id: store_items).destroy_all
			end
		end

		content = ids.to_s.gsub("[", "").gsub("]", "").gsub(",", "")
		path = "./report/remove_store_item_id_"+DateTime.now.to_i.to_s+".txt"
		File.open(path, "w+") do |f|
		  f.write(content)
		end
	end

	# UpdateData.updateItemPrice
	def self.updateItemPrice
		order_items = OrderItem.where("receive > 0 AND grand_total > 0").where(created_at: DateTime.now-2.year..DateTime.now)
		order_items.each do |order_item|
			item = order_item.item
			buy = order_item.grand_total / order_item.receive
			item_price = ItemPrice.create item: item, buy: buy, sell: 0, month: order_item.created_at.month.to_i, year: order_item.created_at.year.to_i, created_at: order_item.created_at
		end
	end
	
	# UpdateData.updateDebtDefZero
	def self.updateDebtDefZero
		orders = Order.where(date_paid_off: nil).where("created_at < '01-01-2022'")
		orders.each do |order|
			db = Debt.where(description: order.invoice).update(deficiency: 0)
			cf = CashFlow.create user: order.user, store: order.store, description: order.invoice, nominal: order.grand_total, date_created: order.date_paid_off, finance_type: CashFlow::OUTCOME, ref_id: order.id, payment: "order"
			it = InvoiceTransaction.create invoice: order.invoice, transaction_type: 0, transaction_invoice: "PAID-" + Time.now.to_i.to_s, date_created: (order.date_receive + 2.days), nominal: order.grand_total.to_f, description: "CASH-BYPASS",user: order.user
		end
	end

	# UpdateData.updateInvoiceTransaction
	def self.updateInvoiceTransaction
		InvoiceTransaction.all.each do |invoice_transaction|
			order = Order.find_by(invoice: invoice_transaction.invoice)
			if order.nil?
				invoice_transaction.destroy
				next
			end
			invoice_transaction.store = order.store
			invoice_transaction.save!
		end
	end
	
	# UpdateData.updateCashFlowInvoice
	def self.updateCashFlowInvoice
		cash_flows = CashFlow.where(finance_type: "Outcome", payment: ["order"])
		cash_flows.each do |cash_flow|
			cash_flow.invoice = "PAID-"+cash_flow.date_created.to_i.to_s
			cash_flow.save!
		end
	end

	# UpdateData.updateDuplicateItem
	def self.updateDuplicateItem
		duplicate_items = Item.select(:code).group(:code).having("count(*) > 1").size
		duplicate_items.each do |duplicate_item|
			items = Item.where(code: duplicate_item[0]).order("updated_at ASC")
			item_ids = items.pluck(:id)
			use_item_id = items.last.id
			remove_ids = item_ids-[use_item_id]
			OrderItem.where(item_id: remove_ids).update_all(item_id: use_item_id)
			TransferItem.where(item_id: remove_ids).update_all(item_id: use_item_id)
			TransactionItem.where(item_id: remove_ids).update_all(item_id: use_item_id)
			GrocerItem.where(item_id: remove_ids).update_all(item_id: use_item_id)
			SupplierItem.where(item_id: remove_ids).update_all(item_id: use_item_id)
			ItemPrice.where(item_id: remove_ids).update_all(item_id: use_item_id)
			SendBackItem.where(item_id: remove_ids).update_all(item_id: use_item_id)
			PopularItem.where(item_id: remove_ids).update_all(item_id: use_item_id)
			NotPopularItem.where(item_id: remove_ids).update_all(item_id: use_item_id)
			LossItem.where(item_id: remove_ids).update_all(item_id: use_item_id)
			Print.where(item_id: remove_ids).update_all(item_id: use_item_id)
			StoreItem.where(item_id: remove_ids).destroy_all
			Item.where(id: remove_ids).destroy_all
		end
	end

	# UpdateData.updateTrxCoin DateTime.now.beginning_of_day
	def self.updateTrxCoin start_date
		end_date = DateTime.now
		trx_items = TransactionItem.where(item_id: 30331, created_at: start_date..end_date)
		trx_items.each do |trx_item|
			trx = trx_item.trx
			trx.has_coin = true
			trx.grand_total_coin = trx_item.total
			trx.hpp_total_coin = trx_item.item.buy * trx_item.quantity
			trx.profit_coin = trx.grand_total_coin - trx.hpp_total_coin
			trx.quantity_coin = trx_item.quantity
			trx.save!
		end
	end

	def self.updateItemDiscountExpired
		end_discounts = Discount.where("end_date <= ?", DateTime.now.beginning_of_day)
		end_discounts.each do |end_disc|
			item = end_disc.item
			item.discount = 0
			item.save!
		end

		start_date = DateTime.now.beginning_of_day
		end_date = start_date.end_of_day
		
		discounts = Discount.where("end_date < ? AND start_date <= ?", end_date, end_date-3.days)
		discounts.each do |disc|
			item = disc.item
			item.discount = disc.discount
			item.save!
		end
	end

	def self.updateItemSellAll
		Item.all.each do |item|
			margin = item.margin
			base_price = item.buy
			tax = item.tax
			next if item.buy == 0

			sell_before_tax = base_price + (base_price*margin/100)
			sell_after_tax = sell_before_tax + (sell_before_tax*tax/100)
			item.sell = sell_after_tax.ceil(-2)
			item.ppn = sell_before_tax*tax/100 
			item.selisih_pembulatan = item.sell - sell_after_tax

			item.save!
		end
	end

	def self.updateItemPPn
		tax = 11
		Supplier.where("tax>0").update_all(tax: tax)
		Item.where("tax>0").update_all(tax: tax)
		Item.where("tax>0").each do |item|
			margin = item.margin
			orders = OrderItem.where(item: item).where("price > 0")
			next if last_order.empty?
			last_order = orders.last
			base_price = last_order.price

			disc_1 = last_order.discount_1
			disc_2 = last_order.discount_2

			disc_1 = 0 if disc_1 < 0 
			disc_2 = 0 if disc_2 < 0

			if disc_1 < 100
				base_price -= base_price*disc_1/100
			else
				base_price -= disc_1/last_order.receive
			end

			if disc_2 < 100
				base_price -= base_price*disc_2/100
			else
				base_price -= disc_2/last_order.receive
			end

			item.buy = base_price

			sell_before_tax = base_price + (base_price*margin/100)
			sell_after_tax = sell_before_tax + (sell_before_tax*tax/100)
			item.sell = sell_after_tax.ceil(-2)
			item.ppn = sell_before_tax*tax/100
			item.selisih_pembulatan = item.sell - sell_after_tax

			item.save!
		end
	end

	def self.updateMarginPpn
		counter = 1
		items = Item.where("selisih_pembulatan > 0").where(discount: 0)
		items.each do |item|
			next if item.buy == 0 || item.sell == 0 || item.discount != 0
			item_margin = item.sell / ((item.tax/100.0)+1)
		  	item.ppn = item.sell - item_margin
		  	item.margin = (((item_margin-item.buy) / item.buy) * 100 ).to_i
		  	item.selisih_pembulatan = item.sell - (item_margin + item.ppn)
	  		item.save!
		end
	end

	# start_date = DateTime.now.beginning_of_month - 6.months
	# end_date = start_date.end_of_month
	# UpdateData.updateTransactionItemColumn start_date, end_date
	def self.updateTransactionItemColumn start_date, end_date
		trxs = Transaction.where(created_at: start_date..end_date)

		trxs.each do |trx|
			trx.transaction_items.update_all(store_id: trx.store.id)
			trx.transaction_items.each do |trx_item|
				supplier_items = SupplierItem.where(item: trx_item.item)
				trx_item.supplier_id = supplier_items.first.supplier.id if supplier_items.present?

				sell = trx_item.price-trx_item.discount
				qty = trx_item.quantity

				trx_item.total = sell * qty
				ppn = sell-(sell/(1+(trx_item.item.tax.to_f/100.0)))
				trx_item.ppn = ppn*qty
				trx_item.profit = (sell-ppn-trx_item.item.buy)*qty

				trx_item.save!
			end
		end
	end

	def check_duplicate_prints
		ids = []
		duplicates = []
		Print.all.each do |print|
			if ids.include? print.item.id
				duplicates << print.id
			else
				ids << print.item.id
			end
		end
	end


end
