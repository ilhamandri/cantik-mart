class Calculate

	def self.calculateData
		Store.all.each do |store|
			calculateStoreData store
		end
	end

	def self.calculateStoreData store	
	    flow_in = [CashFlow::BONUS, CashFlow::INCOME]
	    flow_out = [CashFlow::OPERATIONAL, CashFlow::TAX, CashFlow::OUTCOME]
		debt_val = 0
		receivable_val = 0
		tax_val = 0
		income_val = 0
		outcome_val = 0

		start_date = nil
		end_date = Time.now.beginning_of_month - 1.month
		last_data = StoreData.where(store: store)

		if last_data.present?
			start_date = last_data.last.date
			return if start_date == end_date
			debt_val = StoreData.where(store: store).last.debt 
			receivable_val = StoreData.where(store: store).last.receivable
		else
			start_date = Time.now.beginning_of_year - 3.years
		end

		start_date = start_date + 1.month

		puts "START DATE : " + start_date.to_s 

		dates = [start_date]
		while dates.last != end_date
			dates << (dates.last + 1.month).to_time
		end

		date_range = start_date..(end_date.end_of_month)

		puts "RANGE : " + date_range.to_s
		
		if StoreData.where(store: store).present?
			debt_val = StoreData.where(store: store).last.debt 
			receivable_val = StoreData.where(store: store).last.receivable
		end

		transaction_datas = convertKeyTime Transaction.where(store: store,created_at: date_range).group_by{ |m| m.created_at.beginning_of_month }

		cash_flows = CashFlow.where(store: store)
		income_datas = convertKeyTime cash_flows.where(finance_type: flow_in, created_at: date_range).group_by{ |m| m.created_at.beginning_of_month }
		outcome_datas = convertKeyTime cash_flows.where(finance_type: flow_out, created_at: date_range).group_by{ |m| m.created_at.beginning_of_month }
		tax_datas = convertKeyTime cash_flows.where(finance_type: CashFlow::TAX, created_at: date_range).group_by{ |m| m.created_at.beginning_of_month }
		debt_datas = convertKeyTime Debt.where(store: store,created_at: date_range).group_by{ |m| m.created_at.beginning_of_month }
		receivable_datas = convertKeyTime Receivable.where(store: store,created_at: date_range).group_by{ |m| m.created_at.beginning_of_month }
	    pay_debt_datas = convertKeyTime CashFlow.where(store: store,finance_type: "Outcome", payment: ["debt"],date_created: date_range).group_by{ |m| m.created_at.beginning_of_month }
	    pay_order_datas = convertKeyTime InvoiceTransaction.where(store: store,date_created: date_range).group_by{ |m| m.created_at.beginning_of_month }
	    pay_receivable_datas = CashFlow.where(store: store,finance_type: "Income", payment: ["receivable"]).where(date_created: date_range).group_by{ |m| m.created_at.beginning_of_month }
		
		pay_debt_arr = []
		dates.each_with_index do |date, index|
			store_data = StoreData.new store: store
  			store_data.date = date

  			# DEBT - RECEIVABLE
			debt_data = debt_datas[date]
			debt_nominal = 0
			debt_nominal = debt_data.sum{|data| data.nominal} if debt_data.present?
			debt_val += debt_nominal 

			pay_debt_nominal = 0
			pay_debt_data = pay_debt_datas[date] 
			pay_debt_nominal = pay_debt_data.sum{|data| data.nominal} if pay_debt_data.present?
        	debt_val -= pay_debt_nominal 

        	pay_order_nominal = 0
        	pay_order_data = pay_order_datas[date]
        	pay_order_nominal = pay_order_data.sum{|data| data.nominal} if pay_order_data.present?
        	debt_val -= pay_order_nominal 

        	pay_debt_arr << [debt_nominal, pay_debt_nominal, pay_order_nominal, date.to_date]


			receivable_data = receivable_datas[date]
			receivable_val += receivable_data.sum{|data| data.nominal} if receivable_data.present?
			pay_receivable_data = pay_receivable_datas[date]
        	receivable_val -= pay_receivable_data.sum{|data| data.nominal} if pay_receivable_data.present?

        	store_data.debt = debt_val
        	store.receivable = receivable_val

        	# TRANSACTION
        	transactions = transaction_datas[date]
        	store_data.transaction_total = transactions.sum{|data| data.grand_total} if transactions.present?
	        store_data.transaction_hpp = transactions.sum{|data| data.hpp_total} if transactions.present?
	        store_data.transaction_tax = transactions.sum{|data| data.tax} if transactions.present?
	        store_data.transaction_profit = store_data.transaction_total - store_data.transaction_hpp - store_data.transaction_tax

  			store_data.tax = tax_datas[date].sum{|data| data.nominal} if tax_datas[date].present?
  			
        	store_data.income = income_datas[date].sum{|data| data.nominal} if income_datas[date].present?
        	store_data.outcome = outcome_datas[date].sum{|data| data.nominal} if outcome_datas[date].present?

		    store_data.save!
		end
	end

	def self.convertKeyTime raw_data
		datas = {}
	    raw_data.each do |k,v| 
	        datas[k.to_time] = v
	    end
	    return datas
	end
end  