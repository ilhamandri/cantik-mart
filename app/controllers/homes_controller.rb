class HomesController < ApplicationController
  before_action :require_login
  require 'usagewatch'

  def index
    UpdateData.updateItemDiscountExpired
    ReCheck.complain

    if !["super_admin", "owner", "candy_dream"].include? current_user.level
      @total_limit_items = StoreItem.where(store_id: current_user.store.id).where('stock < min_stock').count
      @total_orders = Order.where(store_id: current_user.store.id).where(date_receive: nil).count
      @total_payments = Order.where(store_id: current_user.store.id).where('date_receive is not null and date_paid_off is null').count
      @total_returs = Retur.where(store_id: current_user.store.id).where(date_picked: nil).count
      @total_transfers = Transfer.where(from_store: current_user.store).where(date_approve: nil).count
    end

    start_day = DateTime.now.beginning_of_day
    end_day = start_day.end_of_day


    # PENGELUARAN
    if ["super_admin", "owner", "finance"].include? current_user.level
      
      cash_flow = CashFlow.where("created_at >= ? AND created_at <= ?", start_day, end_day)
      @operational = cash_flow.where(finance_type: [CashFlow::OPERATIONAL, CashFlow::TAX]).sum(:nominal)
      @fix_cost = cash_flow.where(finance_type: CashFlow::FIX_COST).sum(:nominal)
      
      @total_outcome = @operational + @fix_cost


      @debt = Debt.where("deficiency > ?",0)
      @receivable = Receivable.where("deficiency > ?",0)

    end

    # TRANSAKSI HARI INI
    if ["super_admin", "owner", "candy_dream", "finance"].include? current_user.level
      @transactions = Transaction.where(created_at: start_day..end_day).order("created_at ASC")
      
      if current_user.level == "candy_dream"
        @transactions = @transactions.where(has_coin: true) 
      end
    end


    #DEVELOPER
    if current_user.level == "developer"
      AccountBalance.stock_values current_user.store 
      @debt = Debt.where(store: current_user.store).sum(:deficiency).to_f
      @receivable = Receivable.where(store: current_user.store).sum(:deficiency).to_f
      @stock_value = StockValue.where(store: current_user.store).first.nominal.to_f
      transactions = Transaction.where(store: current_user.store, created_at: DateTime.now.beginning_of_month..DateTime.now.end_of_month)

      # Nilai asset + kas + piutang 
      activa = @stock_value + @receivable
      # Penjualan 
      gross = transactions.sum(:grand_total).to_f
      hpp = transactions.sum(:hpp_total).to_f
      tax = transactions.sum(:tax).to_f
      netto = gross-tax
      profit = netto-hpp

      # LIQUIDITY RATIO
      @quick_ratio = (activa / @debt ) * 100.0

      # PROFIBILITY RATIO
      @gross_profit_margin = (gross/hpp) *100.0
      @net_profit_margin = (profit/netto) * 100.0
      @roi = (@net_profit_margin/@quick_ratio) * 100.0
      # roe dan ronw harus pakai jumlah modal awal

      # SOLVABILITY RATIO
      @solvable = (activa > @debt)

      # ACTIVITY RATIO
      @receivable_turnover = (gross/@receivable) * 100.0
      @total_asset_turnover = (gross/activa) * 100.0
      @average_collection_turnover = ((@receivable/gross) / 365) * 100.0
      @working_capital_turnover = (gross/(activa-@debt)) * 100.0
    end
    
  end

  def popular_items
    trxs = Transaction.where(store: current_user.store).where("created_at >= ?", (DateTime.now - 2.month)).pluck(:id).uniq
    item_sells = TransactionItem.where(transaction_id: trxs).group(:item_id).count
    high_results = Hash[item_sells.sort_by{|k, v| v}.reverse]
    highs = high_results
    curr_date_pop_item = PopularItem.where("date = ?", DateTime.now.beginning_of_month)
    curr_date_pop_item.destroy_all if curr_date_pop_item.present?
    date = DateTime.now.beginning_of_month
    highs.each do |data|
      item = Item.find_by(id: data[0])
      item_cat = item.item_cat
      department = item_cat.department
      sell = data[1]
      pop_item = PopularItem.create item: item, item_cat: item_cat,
       department: department, n_sell: sell, date: date, store: current_user.store
    end
    redirect_success populars_path, "Refresh rekap item selesai."
  end
end
