class Calculate

	def self.graph_debt store
		raw_debts = Debt.all
		raw_debts = raw_debts.where(store: current_user.store) if store.present?
		raw_cash_flows = CashFlow.all
		raw_cash_flows = raw_cash_flows.where(store: current_user.store) if store.present?
		
		start_date = Time.now.beginning_of_month-1.year
	    date_range = start_date..Time.now
	    dates = []

	    13.times do |idx|
	      dates << (start_date + idx.month).to_time
	    end 
	    debt_year_before = raw_debts.where("created_at < ?", start_date).sum(:nominal)
	    paid_year_before = raw_cash_flows.where(finance_type: "Outcome", payment: ["order", "debt"]).where("created_at < ?", start_date).sum(:nominal)
	    
	    raw_debt_datas = raw_debts.where(created_at: date_range).group_by{ |m| m.created_at.beginning_of_month }
	    debt_datas = {}
	    raw_debt_datas.each do |k,v| 
	      debt_datas[k.to_time] = v
	    end
	    pay_data = raw_cash_flows.where(finance_type: "Outcome", payment: ["order", "debt"]).where(created_at: date_range).group_by{ |m| m.created_at.beginning_of_month }
	    
	    debts = {}
	    acumulate = debt_year_before - paid_year_before

	    dates.each do |date|
	      debt_total = 0
	      debt_data = debt_datas[date]
	      debt_total = debt_data.sum{|data| data.nominal} if debt_data.present?
	      
	      paid = 0
	      paid_data = pay_data[date]
	      paid = paid_data.sum{|data| data.nominal} if paid_data.present?
	      
	      acumulate += debt_total - paid
	      debts[date.to_date.strftime("%B %Y")] = acumulate
	    end
	    return debts
	end

	def self.graph_receivable store
		raw_receivables = Receivable.all
		raw_receivables = raw_receivables.where(store: current_user.store) if store.present?
		raw_cash_flows = CashFlow.all
		raw_cash_flows = raw_cash_flows.where(store: current_user.store) if store.present?
		
		start_date = Time.now.beginning_of_month-1.year
	    date_range = start_date..Time.now
	    dates = []

	    13.times do |idx|
	      dates << (start_date + idx.month).to_time
	    end 

	    receivable_year_before = raw_receivables.where("created_at < ?", start_date).sum(:nominal)
	    paid_year_before = raw_cash_flows.where(finance_type: "Income", payment: ["receivable"]).where("created_at < ?", start_date).sum(:nominal)
	    
	    raw_receivable_datas = raw_receivables.where(created_at: date_range).group_by{ |m| m.created_at.beginning_of_month }
	    receivable_datas = {}
	    raw_receivable_datas.each do |k,v| 
	      receivable_datas[k.to_time] = v
	    end
	    pay_data = raw_cash_flows.where(finance_type: "Income", payment: ["receivable"]).where(created_at: date_range).group_by{ |m| m.created_at.beginning_of_month }
	    
	    receivables = {}
	    acumulate = receivable_year_before - paid_year_before

	    dates.each do |date|
	      receivable_total = 0
	      receivable_data = receivable_datas[date]
	      receivable_total = receivable_data.sum{|data| data.nominal} if receivable_data.present?
	      
	      paid = 0
	      paid_data = pay_data[date]
	      paid = paid_data.sum{|data| data.nominal} if paid_data.present?
	      
	      acumulate += receivable_total - paid
	      receivables[date.to_date.strftime("%B %Y")] = acumulate
	    end
	    return receivables
	end

	def self.graph_transaction store
		raw_trxs = Transaction.all
		raw_trxs = raw_trxs.where(store: current_user.store) if store.present?
		
		start_date = (Time.now.beginning_of_month-1.year)
	    date_range = start_date..(Time.now)
	    dates = []

	    13.times do |idx|
	      dates << (start_date + idx.month).to_time
	    end 
	    

	    grouping_trx_datas = raw_trxs.where(created_at: date_range).group_by{ |m| m.created_at.beginning_of_month }
	    trx_datas = {}
	    
	    grouping_trx_datas.each do |k,v| 
	      trx_datas[k.to_time] = v
	    end

	    arr_label = []
	    arr_grand_total = []
	    arr_hpp = []
	    arr_profit = []
	    arr_tax = []

	    dates.each do |date|
	    	trxs = trx_datas[date]
	    	grand_total = hpp = tax = 0

	    	grand_total = trxs.sum{|data| data.grand_total} if trxs.present?
	      	hpp = trxs.sum{|data| data.hpp_total} if trxs.present?
	      	tax = trxs.sum{|data| data.tax} if trxs.present?
	      	profit = grand_total - hpp - tax
	      	
	      	arr_grand_total << grand_total
	      	arr_hpp << hpp
	      	arr_profit << profit
	      	arr_tax << tax
	      	arr_label << date.to_date.strftime("%B %Y")
	    end


	    results = {}

	    results["label"] = arr_label
	    results["grand_total"] = arr_grand_total
	    results["hpp"] = arr_hpp
	    results["tax"] = arr_tax
	    results["profit"] = arr_profit
	    return results
	end

	def self.graph_tax store
		raw_taxs = CashFlow.where(finance_type: CashFlow::TAX)
		raw_taxs = raw_taxs.where(store: current_user.store) if store.present?
		
		start_date = (Time.now.beginning_of_month-1.year)
	    date_range = start_date..(Time.now)
	    dates = []

	    12.times do |idx|
	      dates << (start_date + idx.month).to_time
	    end 
	    

	    grouping_tax_datas = raw_taxs.where(created_at: date_range).group_by{ |m| m.created_at.beginning_of_month }
	    tax_datas = {}
	    
	    grouping_tax_datas.each do |k,v| 
	      tax_datas[k.to_time] = v
	    end

	    results = {}

	    dates.each do |date|
	    	taxs = tax_datas[date]
	    	tax = 0
	      	tax = taxs.sum{|data| data.nominal} if taxs.present?

	      	results[date.to_date.strftime("%B %Y")] = tax
	    end
	    return results
	end

	
	def self.graph_income_outcome store
		flow_in = [CashFlow::BONUS, CashFlow::INCOME]
		flow_out = [CashFlow::OPERATIONAL, CashFlow::TAX, CashFlow::OUTCOME]

		raw_cash_flows_in = CashFlow.where(finance_type: flow_in)
		raw_cash_flows_out = CashFlow.where(finance_type: flow_out)

		raw_cash_flows_in = raw_cash_flows_in.where(store: current_user.store) if store.present?
		raw_cash_flows_out = raw_cash_flows_out.where(store: current_user.store) if store.present?
		
		start_date = (Time.now.beginning_of_month-1.year)
	    date_range = start_date..(Time.now)
	    dates = []

	    12.times do |idx|
	      dates << (start_date + idx.month).to_time
	    end 
	    

	    grouping_cash_flows_in = raw_cash_flows_in.where(created_at: date_range).group_by{ |m| m.created_at.beginning_of_month }
	    grouping_cash_flows_out = raw_cash_flows_out.where(created_at: date_range).group_by{ |m| m.created_at.beginning_of_month }

	    cash_flows_in = {}
	    cash_flows_out = {}
	    
	    grouping_cash_flows_in.each do |k,v| 
	      cash_flows_in[k.to_time] = v
	    end
	    grouping_cash_flows_out.each do |k,v| 
	      cash_flows_out[k.to_time] = v
	    end

	    results = {}

	    arr_label = []
	    arr_income = []
	    arr_outcome = []

	    dates.each do |date|
	    	cash_flow_in = cash_flows_in[date]
	    	cash_flow_out = cash_flows_out[date]

	    	income = 0
	      	income = cash_flow_in.sum{|data| data.nominal} if cash_flow_in.present?

	    	outcome = 0
	      	outcome = cash_flow_out.sum{|data| data.nominal} if cash_flow_out.present?
	      	arr_income << income
	      	arr_outcome << outcome
	      	arr_label << date.to_date.strftime("%B %Y")
	    end

	    results["label"] = arr_label
	    results["income"] = arr_income
	    results["outcome"] = arr_outcome
	   	
	    return results
	end
end  