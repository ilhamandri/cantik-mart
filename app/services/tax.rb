class Tax
	def self.calculate
		Transaction.update_all(tax: 0)
		Order.update_all(tax: 0)
		Supplier.update_all(tax: 0)
		Item.update_all(tax: 0)

		order_items = OrderItem.where("ppn > 0")
		items_id = order_items.pluck(:item_id).uniq
		Item.where(id: items_id).update_all(tax: 10)
		
		orders_id = order_items.pluck(:order_id).uniq
		orders = Order.where(id:orders_id)
		orders.each do |order|
			order.tax = 10 * (order.total.to_f - order.discount.to_f) / 100.0
			order.save!
		end

		suppliers_id = orders.pluck(:supplier_id).uniq
		Supplier.where(id: suppliers_id).update_all(tax: 10)

		TransactionItem.where("created_at>?", DateTime.now.beginning_of_month).where(item_id: items_id).each do |trx_item|
			trx = trx_item.trx
			trx.tax = trx.tax + trx_item.quantity*(trx_item.price-((10.0/11.0)*trx_item.price)).to_i
			trx.save!
		end
	end

end
