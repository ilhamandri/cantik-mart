class Calculate

	def self.graph_debt store
		raw_debts = Debt.all
		raw_debts = Debt.where(store: current_user.store) if store.present?
		raw_cash_flows = CashFlow.all
		raw_cash_flows = CashFlow.where(store: current_user.store) if store.present?
		
		start_date = Time.now.beginning_of_year
	    date_range = Time.now.beginning_of_year..Time.now
	    dates = []

	    Date.today.month.to_i.times do |idx|
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
		raw_receivables = Receivable.where(store: current_user.store) if store.present?
		raw_cash_flows = CashFlow.all
		raw_cash_flows = CashFlow.where(store: current_user.store) if store.present?
		
		start_date = Time.now.beginning_of_year
	    date_range = Time.now.beginning_of_year..Time.now
	    dates = []

	    Date.today.month.to_i.times do |idx|
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
end  