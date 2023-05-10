class ReCheck
	# complain
	def self.complain
		end_date = DateTime.now
		start_date = end_date - 1.day
		trxs = Transaction.where(from_complain: true, created_at:start_date..end_date)
		trxs.each do |trx2|
			trx2_hpp = 0
			trx2.transaction_items.each do |trx2_item|
				trx2_hpp += trx2_item.item.buy.to_i * trx2_item.quantity.to_i
			end
			trx2.hpp_total = trx2_hpp
			trx1 = Transaction.find_by(id: trx2.complain.transaction_id)
			trx1_complain_hpp = 0
			trx1_hpp = 0
			trx1.transaction_items.each do |trx1_item|
				trx1_complain_hpp += (trx1_item.item.buy*trx1_item.retur) if trx1_item.retur.present?
				trx1_hpp += trx1_item.item.buy*trx1_item.quantity
			end
			trx1.hpp_total = trx1_hpp 
			trx2.hpp_total = trx2_hpp - trx1_complain_hpp
			trx2.save!
			trx1.save!
		end
	end

	# HUTANG
	def self.debt
		duplicates = Debt.where("description like 'ORD-%'").select(:description).group(:description).having("count(*) > 1").count
		duplicates.each do |duplicate|
			debts = Debt.where(description: duplicate[0])
			debts.each do |debt|
				debt.destroy
				break
			end
		end
	end

	# PAYMENT
	def self.checkDebtPayment
		debts_id = []
		Debt.where(id: [7193]).each do |debt|
			nominal_debt = debt.nominal
			payments = CashFlow.where(description: debt.description)
			total_payment = payments.sum(:nominal)
			payment_diff = nominal_debt - total_payment
			debt.deficiency = payment_diff
			debt.save!
			next if payment_diff <= 0 || payments.empty?
			debts_id << debt.id
			payments_id = payments.pluck(:id)
			if payments_id.size == 1
				payment = CashFlow.find payments_id.first
				payments.first.update(nominal: payments.first.nominal + payment_diff)
			else
				payments_id.shift(2)
				CashFlow.where(id: payments_id).destroy_all if payments_id.present?
				payments = CashFlow.where(description: debt.description)
				payment_diff = nominal_debt - payments.sum(:nominal)
				payments.last.update(nominal: payments.last.nominal + payment_diff)
			end
			debt.deficiency = 0
			debt.save!
		end
		CashFlow.where(nominal: 0).destroy_all
	end

	# CHECK INVOICE TRX
	def self.checkInvoiceTransaction
		orders_id = []
		Order.all.each do |order|
			nominal_order = order.grand_total
			payments = InvoiceTransaction.where(invoice: order.invoice)
			total_payment = payments.sum(:nominal)
			payment_diff = nominal_order - total_payment
			next if payment_diff <= 0 || payments.empty?

			orders_id << order.id

			payments_id = payments.pluck(:id)
			if payments_id.size == 1
				payment = InvoiceTransaction.find payments_id.first
				payments.first.update(nominal: payments.first.nominal + payment_diff)
			else
				payments_id.shift(2)
				InvoiceTransaction.where(id: payments_id).destroy_all if payments_id.present?
				payments = InvoiceTransaction.where(invoice: order.invoice)
				payment_diff = nominal_order - payments.sum(:nominal)
				next if payment_diff == 0
				payments.last.update(nominal: payments.last.nominal + payment_diff)
			end
			if nominal_order != 0
				debt = Debt.find_by(finance_type: "ORDER", description: order.invoice)
				if debt.present?
					debt.deficiency = 0
					debt.save!
				else
					Debt.create user: order.user, store: order.store, nominal: order.grand_total, deficiency: 0, date_created: order.date_created, ref_id: order.id,description: order.invoice, finance_type: Debt::ORDER,due_date: order.created_at+1.day, supplier_id: order.supplier.id
				end

			end
			order.update(date_paid_off: payments.last.date_created)
		end
		InvoiceTransaction.where(nominal: 0).destroy_all
	end

	def self.checkInvoiceOrder
		start_date = DateTime.now-7.days
		end_date = DateTime.now
		duplicate_orders = Order.where(created_at: start_date..end_date).select(:invoice).group(:invoice).having("count(*) > 1").size
	    duplicate_orders.each do |order_data|
	      orders = Order.where(invoice: order_data[0])
	      order = orders.last

	      store = order.store
	      order.order_items.each do |order_item|
	        store_item = StoreItem.find_by(item: order_item.item, store: store)
	        if order_item.receive.present?
	          store_item.stock = store_item.stock - order_item.receive
	          store_item.save!
	        end
	      end
	      order.order_items.destroy_all
	      order.destroy
	    end
	end
end