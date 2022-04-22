class UpdateData

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

	# UpdateData.updateTransactionItemColumn
	def self.updateTransactionItemColumn
		start_date = DateTime.beginning_of_month
		end_date = DateTime.now.end_of_day
		trxs = Transaction.where(created_at: start_date..end_date)

		trxs.each do |trx|
			trx.transaction_items.update_all(store_id: trx.store.id)
			trx.transaction_items.each do |trx_item|
				supplier_items = SupplierItem.where(item: trx_item.item)
				trx_item.supplier_id = supplier_items.first.supplier.id if supplier_items.present?

				sell = trx_item.price-trx_item.discount
				qty = trx_item.quantity

				trx_item.total = sell * qty
				ppn = sell/(1+trx_item.item.tax)
				trx_item.ppn = ppn*qty
				trx_item.profit = (sell-ppn-trx_item.item.buy)*qty

				trx_item.save!
			end
		end
	end

end