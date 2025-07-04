class HomesController < ApplicationController
  before_action :require_login
  # require 'usagewatch'

  def index

    # DeleteData.clean_data
    
    if  ["super_admin", "developer", "owner"].include? current_user.level
      Thread.start{
        ReCheck.complain
        ReCheck.checkInvoiceOrder
        ReCheck.checkInvoiceTransaction
        Calculate.calculateData
        UpdateData.updateSupplierHandlingLocal
      }
    end

    start_date = DateTime.now.beginning_of_month - 3.months
    end_date = DateTime.now

    @orders = Order.where(store_id: current_user.store.id, created_at: start_date..end_date)

    @total_returs = Retur.where(store_id: current_user.store.id, created_at: start_date..end_date).where("status is null").count

    @total_transfers = Transfer.where(created_at: start_date..end_date).where("from_store_id = ? OR to_store_id = ?", current_user.store.id, current_user.store.id).where(date_approve: nil).count

    @total_send_backs = SendBack.where("received_by is null").where(store: current_user.store).count

    @total_member = Member.where(store: current_user).count

    if current_user.level == "stock_admin"
      c_start = DateTime.now.beginning_of_month - 3.months
      c_end = DateTime.now.end_of_year
      order_data = Order.where(created_at: c_start..c_end)
      order_item_data = TransactionItem.where(created_at: c_start..c_end)
      @top_suppliers = Hash[order_data.group(:supplier_id).count.sort_by{|k,v| v}.reverse]
      @top_items = Hash[order_item_data.group(:item_id).count.sort_by{|k,v| v}.reverse]
    end

    start_day = DateTime.now.beginning_of_day
    end_day = start_day.end_of_day

    # PENGELUARAN
    if ["super_admin", "owner", "finance", "developer"].include? current_user.level
      cash_flow = CashFlow.where(created_at: start_day..end_day)
      cash_flow = cash_flow.where(store: current_user.store) if current_user.level == "super_visi"
      @operational = cash_flow.where(finance_type: [CashFlow::OPERATIONAL, CashFlow::TAX]).sum(:nominal)
      @fix_cost = cash_flow.where(finance_type: CashFlow::FIX_COST).sum(:nominal)
      
      @total_outcome = @operational + @fix_cost

      @debt = Debt.where("deficiency > ?",0).where(store: current_user.store) 
      @receivable = Receivable.where("deficiency > ?",0).where(store: current_user.store)\
    end

    # TRANSAKSI HARI INI
    if ["super_admin", "owner", "finance", "super_visi", "developer"].include? current_user.level
      @daily_transaction = Transaction.where(created_at: start_day..end_day)
      start_month_before = DateTime.now.beginning_of_month-1.month
      end_month_beofre = start_month_before.end_of_month
      if current_user.level != "candy_dream"
        @transactions = Transaction.where(created_at: start_month_before..end_month_beofre)
      end
    end

    if current_user.level == "candy_dream"
      start_month_before = DateTime.now.beginning_of_month-1.month
      end_month_beofre = start_month_before.end_of_month
      @transactions = Transaction.where(has_coin: true, created_at: start_month_before..end_month_beofre)
      
      curr_month_start = DateTime.now.beginning_of_month
      curr_month_end = curr_month_start.end_of_month
      @curr_month_transactions = Transaction.where(has_coin: true, date_created: curr_month_start..curr_month_end) 
    end

    #DEVELOPER
    if false
      AccountBalance.stock_values current_user.store 
      debt = Debt.where(store: current_user.store).sum(:deficiency).to_f
      receivable = Receivable.where(store: current_user.store).sum(:deficiency).to_f
      @stock_value = StockValue.where(store: current_user.store).first.nominal.to_f
      transactions = Transaction.where(store: current_user.store, created_at: DateTime.now.beginning_of_month..DateTime.now.end_of_month)

      # Nilai asset + kas + piutang 
      activa = @stock_value + receivable
      
      # Penjualan 
      gross = transactions.sum(:grand_total).to_f
      hpp = transactions.sum(:hpp_total).to_f
      tax = transactions.sum(:tax).to_f
      netto = gross-tax
      profit = netto-hpp

      # LIQUIDITY RATIO
      @quick_ratio = (activa / debt ) * 100.0

      # PROFIBILITY RATIO
      @gross_profit_margin = (gross/hpp) *100.0
      @net_profit_margin = (profit/netto) * 100.0
      @roi = (@net_profit_margin/@quick_ratio) * 100.0
      # roe dan ronw harus pakai jumlah modal awal

      # SOLVABILITY RATIO
      @solvable = (activa > debt)

      # ACTIVITY RATIO
      @receivable_turnover = (gross/receivable) * 100.0
      @total_asset_turnover = (gross/activa) * 100.0
      @average_collection_turnover = ((receivable/gross) / 365) * 100.0
      @working_capital_turnover = (gross/(activa-debt)) * 100.0

      
      debts = Serve.graph_debt dataFilter
      gon.debt_label = debts.keys
      gon.debt_data = debts.values

      receivables = Serve.graph_receivable dataFilter
      gon.receivable_label = receivables.keys
      gon.receivable_data = receivables.values

      trxs = Serve.graph_transaction dataFilter
      gon.transaction_label = trxs["label"]
      gon.transaction_omzet = trxs["grand_total"]
      gon.transaction_hpp = trxs["hpp"]
      gon.transaction_tax = trxs["tax"]
      gon.transaction_profit = trxs["profit"]

      taxs = Serve.graph_tax dataFilter
      gon.tax_label = taxs.keys
      gon.tax_data = taxs.values
      
      income_outcomes = Serve.graph_income_outcome dataFilter
      gon.income_outcome_label = income_outcomes["label"]
      gon.income_data = income_outcomes["income"]   
      gon.outcome_data = income_outcomes["outcome"]   
    end
    
  end

  def popular_items
    # trxs = Transaction.where(store: current_user.store).where("created_at >= ?", (DateTime.now - 2.month)).pluck(:id).uniq
    # item_sells = TransactionItem.where(transaction_id: trxs).group(:item_id).count
    # high_results = Hash[item_sells.sort_by{|k, v| v}.reverse]
    # highs = high_results
    # curr_date_pop_item = PopularItem.where("date = ?", DateTime.now.beginning_of_month)
    # curr_date_pop_item.destroy_all if curr_date_pop_item.present?
    # date = DateTime.now.beginning_of_month
    # highs.each do |data|
    #   item = Item.find_by(id: data[0])
    #   item_cat = item.item_cat
    #   department = item_cat.department
    #   sell = data[1]
    #   pop_item = PopularItem.create item: item, item_cat: item_cat,
    #    department: department, n_sell: sell, date: date, store: current_user.store
    # end
    redirect_success populars_path, "Refresh rekap item selesai."
  end

end
