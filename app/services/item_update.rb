class ItemUpdate

	def self.updateItem
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
end