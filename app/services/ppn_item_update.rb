class PpnItemUpdate
	def self.updateItem
		tax = 11
		Supplier.where("tax>0").update_all(tax: tax)
		Item.where("tax>0").update_all(tax: tax)
		Item.where("tax>0").each do |item|
			margin = item.margin
			last_order = OrderItem.where(item: item).last
			next if last_order.nil?
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