class HomesController < ApplicationController
  before_action :require_login
  require 'usagewatch'

  def losses start_day, end_day
    loss_val = 0
    Store.all.each do |store|
      losses = Loss.where("created_at >= ? AND created_at <= ?", start_day, end_day)
      losses.each do |loss|
        losses_items = loss.loss_items
        losses_items.each do |loss|
          store_stock = StoreItem.find_by(store: store, item: loss.item)
          loss_val += (loss.quantity * store_stock.item.buy) if !store_stock.item.local_item
          loss_val += (loss.quantity * store_stock.buy) if store_stock.item.local_item
        end
      end
    end
    return loss_val
  end

  def index
    ItemUpdate.updateItem
    UserMethod.where(user_level: ["driver", "preamuniaga", "cashier"]).destroy_all

    @total_limit_items = StoreItem.where(store_id: current_user.store.id).where('stock < min_stock').count
    @total_orders = Order.where(store_id: current_user.store.id).where('date_receive is null').count
    @total_payments = Order.where(store_id: current_user.store.id).where('date_receive is not null and date_paid_off is null').count
    @total_returs = Retur.where(store_id: current_user.store.id).where('date_picked is null').count
    
    if ["driver", "owner","super_admin", "stock_admin", "super_visi"].include? current_user.level
      item_cats_data = higher_item_cats_graph
      gon.higher_item_cats_data = item_cats_data.values
      gon.higher_item_cats_label = item_cats_data.keys

      item_cats_data = lower_item_cats_graph
      gon.lower_item_cats_data = item_cats_data.values
      gon.lower_item_cats_label = item_cats_data.keys

      
      @higher_item = higher_item
      @lower_item = lower_item
    end

    # PENGELUARAN
    end_day = DateTime.now.end_of_day
    start_day = end_day.beginning_of_day
    cash_flow = CashFlow.where("created_at >= ? AND created_at <= ?", start_day, end_day)
    @operational = cash_flow.where(finance_type: [CashFlow::OPERATIONAL, CashFlow::TAX]).sum(:nominal)
    @fix_cost = cash_flow.where(finance_type: CashFlow::FIX_COST).sum(:nominal)
    @losses = losses(start_day, end_day)
    @other_outcome = cash_flow.where(finance_type: CashFlow::OUTCOME).sum(:nominal)
    
    @total_outcome = @operational + @fix_cost + @losses + @other_outcome

    # graphs_buy_sell = transactions_profit_graph

    # graphs_buy_sell_val = graphs_buy_sell.values
    # grand_totals = graphs_buy_sell_val.collect{|ind| ind[0]}.reverse
    # gon.grand_totals = grand_totals

    # hpp_totals = graphs_buy_sell_val.collect{|ind| ind[1]}.reverse
    # gon.hpp_totals = hpp_totals

    # profits = graphs_buy_sell_val.collect{|ind| ind[2]}.reverse
    # gon.profits = profits

    # gon.month = graphs_buy_sell.keys.reverse

    # days
    # graphs_buy_sell = transactions_profit_graph_days

    # graphs_buy_sell_val = graphs_buy_sell.values
    # grand_totals = graphs_buy_sell_val.collect{|ind| ind[0]}
    # gon.grand_totals_days = grand_totals

    # hpp_totals = graphs_buy_sell_val.collect{|ind| ind[1]}
    # gon.hpp_totals_days = hpp_totals

    # profits = graphs_buy_sell_val.collect{|ind| ind[2]}
    # gon.profits_days = profits

    # gon.month_days = graphs_buy_sell.keys    

    # popular_item

    @debt = Debt.where("deficiency > ?",0)
    @receivable = Receivable.where("deficiency > ?",0)\



    start_day = DateTime.now.beginning_of_day
    end_day = start_day.end_of_day
    @transactions = Transaction.where("created_at >= ? AND created_at <= ?", start_day, end_day)
    @transactions = @transactions.order("created_at DESC")
    @cashiers = @transactions.pluck(:user_id)
    # RecapMailer.new_recap_email(@transactions, @cashiers).deliver_now

  end

  def popular_items
    item_sells = TransactionItem.where("created_at >= ?", DateTime.now - 1.month).group(:item_id).count
    high_results = Hash[item_sells.sort_by{|k, v| v}.reverse]
    low_results = Hash[item_sells.sort_by{|k, v| v}]
    highs = high_results
    lows = low_results
    curr_date_pop_item = PopularItem.where("date = ?", Date.today)
    curr_date_pop_item.destroy_all if curr_date_pop_item.present?
    highs.each do |data|
      item = Item.find_by(id: data[0])
      item_cat = item.item_cat
      department = item_cat.department
      sell = data[1]
      pop_item = PopularItem.create item: item, item_cat: item_cat,
       department: department, n_sell: sell, date: Date.today
    end
    lows.each do |data|
      item = Item.find_by(id: data[0])
      item_cat = item.item_cat
      department = item_cat.department
      sell = data[1]
      pop_item = NotPopularItem.create item: item, item_cat: item_cat,
       department: department, n_sell: sell, date: Date.today
    end
    redirect_success root_path, "Refresh rekap item selesai."
  end

  private
    def transactions_profit_graph
      transactions = Transaction.where("created_at >= ?", DateTime.now.beginning_of_year-13.months).order("created_at ASC")
      if !["driver","owner", "super_admin"].include? current_user.level
        transactions = transactions.where(store: current_user.store)
      end

      transaction_datas = transactions.group_by{ |m| m.created_at.beginning_of_month}

      graphs_buy_sell = {}

      13.times do |i|
        date = Date.today - i.month
        month = date.strftime("%B %Y")
        graphs_buy_sell[month] = [0,0,0]
      end

      transaction_datas.each do |trxs|
        grand_total = 0
        hpp_total = 0
        month = trxs.first.to_date.strftime("%B %Y")
        trxs[1].each do |trx|
          grand_total += trx.grand_total
          hpp_total += trx.hpp_total
        end

        profit = grand_total - hpp_total
        graphs_buy_sell[month] = [grand_total, hpp_total, profit]
      end

      return graphs_buy_sell
    end

    def transactions_profit_graph_days
      transactions = Transaction.where("created_at >= ?", DateTime.now.beginning_of_year-13.months).order("created_at ASC")
      if !["visitor", "owner", "super_admin", "driver"].include? current_user.level
        transactions = transactions.where(store: current_user.store)
      end

      transaction_datas = transactions.group_by{ |m| m.created_at.beginning_of_day}

      graphs_buy_sell = {}

      transaction_datas.each do |trxs|
        grand_total = 0
        hpp_total = 0
        d = trxs.first.to_date.strftime("%d %B %Y")
        trxs[1].each do |trx|
          grand_total += trx.grand_total
          hpp_total += trx.hpp_total
        end

        profit = grand_total - hpp_total
        graphs_buy_sell[d] = [grand_total, hpp_total, profit]
      end

      return graphs_buy_sell
    end

    def higher_item
      item_sells = PopularItem.where("date = ?", PopularItem.last.date).order("n_sell DESC").limit(20).pluck(:item_id, :n_sell)
      return Hash[item_sells]
    end

    def lower_item
      item_sells = PopularItem.where("date = ?", PopularItem.last.date).order("n_sell ASC").limit(20).pluck(:item_id, :n_sell)
      return Hash[item_sells]
    end

    def higher_item_cats_graph
      item_cats = {}
      item_sells = PopularItem.where("date = ?", PopularItem.last.date).order("n_sell DESC").limit(100).pluck(:item_id, :n_sell)
      item_sells.each do |item_sell|
        item_id = item_sell[0]
        sell_qty = item_sell[1]
        item_cat_name = Item.find(item_id).item_cat.name
        item_cats[item_cat_name] = sell_qty
      end
      sort_results = Hash[item_cats.sort_by{|k, v| v}.reverse]
      results = sort_results.first(10)
      return Hash[results]
    end

    def lower_item_cats_graph
      item_cats = {}
      item_sells = PopularItem.where("date = ?", PopularItem.last.date).order("n_sell ASC").limit(100).pluck(:item_id, :n_sell)
      item_sells.each do |item_sell|
        item_id = item_sell[0]
        sell_qty = item_sell[1]
        item_cat_name = Item.find(item_id).item_cat.name
        item_cats[item_cat_name] = sell_qty
      end
      sort_results = Hash[item_cats.sort_by{|k, v| v}.reverse]
      results = sort_results.first(10)
      return Hash[results]
    end

end
