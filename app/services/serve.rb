class Serve 

  def self.transactions_graph_manual start_day, end_day, group_type, current_user
    trxs = nil
    if current_user.level == "candy_dream"
      trxs = Transaction.where(has_coin: true) 
    else
      trxs = Transaction.where(has_coin: false) 
    end
    transaction_datas = nil
    if group_type == "daily"
      transaction_datas = trxs.where(created_at: start_day..end_day).group_by{ |m| m.created_at.beginning_of_day}
    else 
      transaction_datas = trxs.where(created_at: start_day..end_day).group_by{ |m| m.created_at.beginning_of_month}
    end
    results = {}
    arr_label = []
    arr_grand_total = []
    arr_hpp = []
    arr_tax = []
    arr_profit = []
    
    transaction_datas.each do |date, datas|
      arr_label << date.to_date.strftime("%d %B %Y") if group_type == "daily"
      arr_label << date.to_date.strftime("%B %Y") if group_type == "monthly"
      if current_user.level == "candy_dream"
        arr_grand_total << datas.sum{|data| data.grand_total_coin}
      else
        arr_grand_total << datas.sum{|data| data.grand_total}
        arr_hpp << datas.sum{|data| data.hpp_total}
        arr_tax << datas.sum{|data| data.tax}
        arr_profit << arr_grand_total.last - arr_hpp.last - arr_tax.last
      end
    end
    results["label"] = arr_label
    results["grand_total"] = arr_grand_total
    results["hpp"] = arr_hpp
    results["tax"] = arr_tax
    results["profit"] = arr_profit

    return results
  end 

  def self.graph_debt store
    start_date = Time.now.beginning_of_month-1.year
    date_range = start_date..Time.now.beginning_of_month-1.month
    raw_debts = StoreData.where(date: date_range)
    raw_debts = raw_debts.where(store: store) if store.present?

    debt_datas = raw_debts.group_by{ |m| m.date }
    
    results = {}
    debt_datas.each do |date, datas|
      results[date.to_date.strftime("%B %Y")] = datas.sum{|data| data.debt}
    end

    return results

  end

  def self.graph_receivable store
    start_date = Time.now.beginning_of_month-1.year
    date_range = start_date..Time.now.beginning_of_month-1.month
    raw_receivables = StoreData.where(date: date_range)
    raw_receivables = raw_receivables.where(store: store) if store.present?

    receivable_datas = raw_receivables.group_by{ |m| m.date }
    
    results = {}
    receivable_datas.each do |date, datas|
      results[date.to_date.strftime("%B %Y")] = datas.sum{|data| data.receivable}
    end

    return results
  end

  def self.graph_transaction store
    start_date = Time.now.beginning_of_month-1.year
    date_range = start_date..Time.now.beginning_of_month-1.month
    raw_transactions = StoreData.where(date: date_range)
    raw_transactions = raw_transactions.where(store: store) if store.present?

    transaction_datas = raw_transactions.group_by{ |m| m.date }
    
    arr_label = []
    arr_grand_total = []
    arr_hpp = []
    arr_tax = []
    arr_profit = []

    results = {}
    transaction_datas.each do |date, datas|
      arr_label << date.to_date.strftime("%B %Y")
      arr_grand_total << datas.sum{|data| data.transaction_total}
      arr_hpp << datas.sum{|data| data.transaction_hpp}
      arr_tax << datas.sum{|data| data.transaction_tax}
      arr_profit << datas.sum{|data| data.transaction_profit}
    end
    results["label"] = arr_label
    results["grand_total"] = arr_grand_total
    results["hpp"] = arr_hpp
    results["tax"] = arr_tax
    results["profit"] = arr_profit

    return results
  end

  def self.graph_tax store
    start_date = Time.now.beginning_of_month-1.year
    date_range = start_date..Time.now.beginning_of_month-1.month
    raw_taxs = StoreData.where(date: date_range)
    raw_taxs = raw_taxs.where(store: store) if store.present?

    tax_datas = raw_taxs.group_by{ |m| m.date }
    
    results = {}
    tax_datas.each do |date, datas|
      results[date.to_date.strftime("%B %Y")] = datas.sum{|data| data.tax}
    end

    return results
  end

  
  def self.graph_income_outcome store
    start_date = Time.now.beginning_of_month-1.year
    date_range = start_date..Time.now.beginning_of_month-1.month
    raw_transactions = StoreData.where(date: date_range)
    raw_transactions = raw_transactions.where(store: store) if store.present?

    transaction_datas = raw_transactions.group_by{ |m| m.date }
    
    arr_label = []
    arr_income = []
    arr_outcome = []

    results = {}
    transaction_datas.each do |date, datas|
      arr_label << date.to_date.strftime("%B %Y")
      arr_income << datas.sum{|data| data.income}
      arr_outcome << datas.sum{|data| data.outcome}
    end
    results["label"] = arr_label
    results["income"] = arr_income
    results["outcome"] = arr_outcome

    return results
  end
end