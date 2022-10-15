class Serve 

  def self.transactions_graph_manual start_day, end_day, group_type, current_user, store
    trxs = nil
    if current_user.level == "candy_dream"
      trxs = Transaction.where(has_coin: true) 
    else
      trxs = Transaction.where(has_coin: false) 
    end
    
    trxs = trxs.where(store: store) if store.present?

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

  def self.graph_absent user
    start_date = Time.now.beginning_of_day - 1.month
    date_range = start_date..Time.now.end_of_day
    raw_absent = Absent.where(check_in: date_range, user: user)
    dates = [start_date]
    while true
      dates << dates.last + 1.day 
      break if Time.now.beginning_of_day == dates.last
    end

    absent_data = raw_absent.group_by{ |m| m.created_at.beginning_of_day}

    result = {}
    
    dates.each do |date|
      absents = absent_data[date]
      work_hour = 0.0
      if absents.present?
        absent = absents.first
        work_hour_raw = absent.work_hour.split(":")
        work_hour += work_hour_raw[0].to_f
        work_hour += (work_hour_raw[1].to_f / 100)
        work_hour += 1 if work_hour_raw[2].to_f > 0
      end
      result[date.to_date.strftime("%d %B %Y")] = work_hour
    end

    return result
  end

  def self.graph_item_price item
    start_date = Time.now.beginning_of_month-1.year
    date_range = start_date..Time.now.end_of_month
    raw_price = ItemPrice.where(created_at: date_range, item: item)
    dates = [start_date]
    
    20.times do |index|
      dates << dates.last + 1.month 
      break if Time.now.end_of_month == dates.last.end_of_month
    end

    sell_data = raw_price.where("sell > 0").group_by{ |m| m.created_at.beginning_of_month}
    buy_data = raw_price.where("buy > 0").group_by{ |m| m.created_at.beginning_of_month}

    arr_label = []
    arr_buy = []
    arr_sell = []

    dates.each do |date|
      arr_label << date.to_date.strftime("%B %Y")

      buys = buy_data[date]
      sells = sell_data[date]

      buy = 0
      buy = buys.sum{|data| data.buy} / buys.size if buys.present?
      sell = 0
      sell = sells.sum{|data| data.sell} / sells.size if sells.present?
      
      arr_buy << buy
      arr_sell << sell
    end

    first_buy = 0
    temp = 0
    arr_buy.each_with_index do |buy, idx|
      first_buy = buy if first_buy == 0 && buy != 0
      temp = buy if buy != 0
      arr_buy[idx] = temp if arr_buy[idx] == 0
    end
    arr_buy = arr_buy.map { |x| x == 0 ? first_buy : x }

    first_sell = 0
    temp = 0
    arr_sell.each_with_index do |sell, idx|
      first_sell = sell if first_sell == 0 && sell != 0
      temp = sell if sell != 0
      arr_sell[idx] = temp if arr_sell[idx] == 0
    end
    arr_sell = arr_sell.map { |x| x == 0 ? first_sell : x }

    results = {}
    results["label"] = arr_label
    results["buy"] = arr_buy
    results["sell"] = arr_sell

    return results
  end


  def self.graph_item_order_sell store, item
    start_date = Time.now.beginning_of_month-1.year
    date_range = start_date..Time.now.end_of_month
    raw_order = OrderItem.where(created_at: date_range, item: item)
    raw_transaction = TransactionItem.where(created_at: date_range, item: item)
    dates = [start_date]
    
    20.times do |index|
      dates << dates.last + 1.month 
      break if Time.now.end_of_month == dates.last.end_of_month
    end

    trx_datas = raw_transaction.group_by{ |m| m.created_at.beginning_of_month}
    order_datas = raw_order.group_by{ |m| m.created_at.beginning_of_month}

    arr_label = []
    arr_order = []
    arr_transaction = []

    dates.each do |date|
      arr_label << date.to_date.strftime("%B %Y")
      trx = 0
      trxs = trx_datas[date]
      trx = trxs.sum{|data| data.quantity} if trxs.present?

      order = 0
      orders = order_datas[date]
      order = orders.sum{|data| data.receive} if orders.present?

      arr_order << order
      arr_transaction << trx
      
    end

    results = {}
    results["label"] = arr_label
    results["transaction"] = arr_transaction
    results["order"] = arr_order

    return results
  
  end

  def self.loss_graph_monthly store
    date_range = Time.now.beginning_of_month-1.year..Time.now.end_of_month
    raw_loss = Loss.where(created_at: date_range)
    raw_loss = raw_loss.where(store: store) if store.present?

    loss_datas = raw_loss.group_by{ |m| m.created_at.beginning_of_month}
    
    results = {}
    arr_label = []
    arr_loss = []
    arr_loss_item = []
    
    loss_datas.each do |date, datas|
      arr_label << date.to_date.strftime("%B %Y")
     
      arr_loss << datas.size
      arr_loss_item << datas.sum{|data| data.total_item}
    end
    results["label"] = arr_label
    results["loss"] = arr_loss
    results["loss_item"] = arr_loss_item
    return results
  end 

  def self.loss_item_graph_monthly store, item
    raw_loss = LossItem.where(item: item)

    results = {}
    
    return results if raw_loss.empty?

    raw_loss = raw_loss.where(store: store) if store.present?

    loss_datas = raw_loss.group_by{ |m| m.created_at.beginning_of_month}

    arr_label = []
    arr_loss = []
    arr_loss_item = []
    
    loss_datas.each do |date, datas|
      arr_label << date.to_date.strftime("%B %Y")
      arr_loss_item << datas.sum{|data| data.quantity}
    end
    results["label"] = arr_label
    results["loss_item"] = arr_loss_item
    return results
  end 

  def self.order_graph_monthly store, supplier
    date_range = Time.now.beginning_of_month-1.year..Time.now.end_of_month
    raw_order = Order.where(created_at: date_range)
    raw_order = raw_order.where(store: store) if store.present?
    raw_order = raw_order.where(supplier: supplier) if supplier.present?

    order_datas = raw_order.group_by{ |m| m.created_at.beginning_of_month}
    
    results = {}
    arr_label = []
    arr_order= []
    arr_order_nominal = []
    
    order_datas.each do |date, datas|
      arr_label << date.to_date.strftime("%B %Y")
     
      arr_order<< datas.size
      arr_order_nominal << datas.sum{|data| data.grand_total}
    end
    results["label"] = arr_label
    results["order"] = arr_order
    results["order_nominal"] = arr_order_nominal
    return results
  end

  def self.supplier_trx_graph_monthly store, supplier
    items = SupplierItem.where(supplier: supplier).pluck(:item_id)
    date_range = Time.now.beginning_of_month-1.year..Time.now.end_of_month
    raw_trxs = TransactionItem.where(created_at: date_range, item_id: items)
    raw_trxs = raw_trxs.where(store: store) if store.present?

    trx_datas = raw_trxs.group_by{ |m| m.created_at.beginning_of_month}
    results = {}
    arr_label = []
    arr_trx_items= []
    arr_trx_nominal = []
    
    trx_datas.each do |date, datas|
      arr_label << date.to_date.strftime("%B %Y")
     
      arr_trx_items<< datas.size
      arr_trx_nominal << datas.sum{|data| data.total}
    end
    results["label"] = arr_label
    results["trx_items"] = arr_trx_items
    results["trx_nominal"] = arr_trx_nominal
    return results
  end


  def self.retur_graph_monthly store
    date_range = Time.now.beginning_of_month-1.year..Time.now.end_of_month
    raw_returs = Retur.where(created_at: date_range)
    raw_returs = raw_returs.where(store: store) if store.present?

    retur_datas = raw_returs.group_by{ |m| m.created_at.beginning_of_month}

    results = {}
    arr_label = []
    arr_retur = []
    arr_retur_item = []
    
    retur_datas.each do |date, datas|
      arr_label << date.to_date.strftime("%B %Y")
     
      arr_retur << datas.size
      arr_retur_item << datas.sum{|data| data.total_items}
    end
    results["label"] = arr_label
    results["retur"] = arr_retur
    results["retur_item"] = arr_retur_item
    return results
  end 

  def self.complain_graph_monthly store
    date_range = Time.now.beginning_of_month-1.year..Time.now.end_of_month
    raw_complains = Complain.where(created_at: date_range)
    raw_complains = raw_complains.where(store: store) if store.present?

    complain_datas = raw_complains.group_by{ |m| m.created_at.beginning_of_month}

    results = {}
    arr_label = []
    arr_complain = []
    arr_complain_item = []
    
    complain_datas.each do |date, datas|
      arr_label << date.to_date.strftime("%B %Y")
     
      arr_complain << datas.size
      arr_complain_item << datas.sum{|data| data.total_items}
    end
    results["label"] = arr_label
    results["complain"] = arr_complain
    results["complain_item"] = arr_complain_item
    return results
  end 

  def self.graph_debt store
    date_range = Time.now.beginning_of_month-1.year..Time.now.beginning_of_month
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
    date_range = start_date..Time.now.beginning_of_month
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
    date_range = start_date..Time.now.beginning_of_month
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
    date_range = start_date..Time.now.beginning_of_month
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
    date_range = start_date..Time.now.beginning_of_month
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