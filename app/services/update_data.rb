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

end