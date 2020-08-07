class HomesController < ApplicationController
  before_action :require_login
  require 'usagewatch'

  def index
    ItemUpdate.updateItem
    UserMethod.where(user_level: ["driver", "preamuniaga", "cashier"]).destroy_all

    @total_limit_items = StoreItem.where(store_id: current_user.store.id).where('stock < min_stock').count
    @total_orders = Order.where(store_id: current_user.store.id).where('date_receive is null').count
    @total_payments = Order.where(store_id: current_user.store.id).where('date_receive is not null and date_paid_off is null').count
    @total_returs = Retur.where(store_id: current_user.store.id).where('date_picked is null').count
    

    # PENGELUARAN
    end_day = DateTime.now.end_of_day
    start_day = end_day.beginning_of_day
    cash_flow = CashFlow.where("created_at >= ? AND created_at <= ?", start_day, end_day)
    @operational = cash_flow.where(finance_type: [CashFlow::OPERATIONAL, CashFlow::TAX]).sum(:nominal)
    @fix_cost = cash_flow.where(finance_type: CashFlow::FIX_COST).sum(:nominal)
    
    @total_outcome = @operational + @fix_cost


    @debt = Debt.where("deficiency > ?",0)
    @receivable = Receivable.where("deficiency > ?",0)



    start_day = DateTime.now.beginning_of_day
    end_day = start_day.end_of_day
    @transactions = Transaction.where("created_at >= ? AND created_at <= ?", start_day, end_day)
    @transactions = @transactions.order("created_at DESC")
    
    if current_user.level == "candy_dream"
      @transactions = @transactions.where(has_coin: true) 
    else
      @transactions = @transactions.where(has_coin: false)
    end

    @cashiers = @transactions.pluck(:user_id)
    
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
