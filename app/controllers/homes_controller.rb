class HomesController < ApplicationController
  before_action :require_login
  require 'usagewatch'

  def index
    @total_limit_items = StoreItem.where(store_id: current_user.store.id).where('stock < min_stock').count
    @total_orders = Order.where(store_id: current_user.store.id).where('date_receive is null').count
    @total_payments = Order.where(store_id: current_user.store.id).where('date_receive is not null and date_paid_off is null').count
    @total_returs = Retur.where(store_id: current_user.store.id).where('date_picked is null').count
    # item_cats_data = higher_item_cats_graph
    # gon.higher_item_cats_data = item_cats_data.values
    # gon.higher_item_cats_label = item_cats_data.keys

    # item_cats_data = lower_item_cats_graph
    # gon.lower_item_cats_data = item_cats_data.values
    # gon.lower_item_cats_label = item_cats_data.keys

    # transactions = transactions_profit_graph
    # gon.grand_totals = transactions[0]
    # gon.hpp_totals = transactions[1]
    # gon.profits = transactions[2]

    # @higher_item = higher_item
    # @lower_item = lower_item

    @debt = Debt.where("deficiency > ?",0)
    @receivable = Receivable.where("deficiency > ?",0)\



    # start_day = DateTime.now.beginning_of_day-1.day
    # end_day = start_day.end_of_day
    # @transactions = Transaction.where("created_at >= ? AND created_at <= ?", start_day, end_day)
    # @transactions = @transactions.order("created_at DESC")
    # @cashiers = @transactions.pluck(:user_id)
    # RecapMailer.new_recap_email(@transactions, @cashiers).deliver_now

  end

  private
    def transactions_profit_graph
      transactions = Transaction.where("created_at >= ? AND created_at <= ?", DateTime.now.beginning_of_year, DateTime.now.end_of_year).order("created_at DESC")
      if !["owner", "super_admin"].include? current_user.level
        transactions = transactions.where(store: current_user.store)
      end
      transaction_datas = transactions.group_by{ |m| m.created_at.beginning_of_month}
      
      grand_totals = [0,0,0,0,0,0,0,0,0,0,0,0]
      hpp_totals = [0,0,0,0,0,0,0,0,0,0,0,0]
      profits = [0,0,0,0,0,0,0,0,0,0,0,0]

      transaction_datas.each do |trxs|
        grand_total = 0
        hpp_total = 0
        month_idx = trxs[0].month.to_i - 1
        trxs[1].each do |trx|
          grand_total += trx.grand_total
          hpp_total += trx.hpp_total
        end
        profit = grand_total - hpp_total
        grand_totals[month_idx] = grand_total
        hpp_totals[month_idx] = hpp_total
        profits[month_idx] = profit
      end

      return [grand_totals, hpp_totals, profits]
    end

    def higher_item
      item_sells = TransactionItem.group(:item_id).count
      sort_results = Hash[item_sells.sort_by{|k, v| v}.reverse]
      result = sort_results.first(5)
      return Hash[result]
    end

    def lower_item
      item_sells = TransactionItem.group(:item_id).count
      sort_results = Hash[item_sells.sort_by{|k, v| v}]
      result = sort_results.first(5)
      return Hash[result]
    end

    def higher_item_cats_graph
      item_cats = {}
      item_sells = TransactionItem.pluck(:item_id, :quantity)
      item_sells.each do |item_sell|
        item_id = item_sell[0]
        sell_qty = item_sell[1]
        item_cat_name = Item.find(item_id).item_cat.name
        if item_cats[item_cat_name].present?
          new_total_qty = item_cats[item_cat_name] + sell_qty
          item_cats[item_cat_name] = new_total_qty
        else
          item_cats[item_cat_name] = sell_qty
        end
      end
      sort_results = Hash[item_cats.sort_by{|k, v| v}.reverse]
      results = sort_results.first(5)
      return Hash[results]
    end

    def lower_item_cats_graph
      item_cats = {}
      item_sells = TransactionItem.pluck(:item_id, :quantity)
      item_sells.each do |item_sell|
        item_id = item_sell[0]
        sell_qty = item_sell[1]
        item_cat_name = Item.find(item_id).item_cat.name
        if item_cats[item_cat_name].present?
          new_total_qty = item_cats[item_cat_name] + sell_qty
          item_cats[item_cat_name] = new_total_qty
        else
          item_cats[item_cat_name] = sell_qty
        end
      end
      sort_results = Hash[item_cats.sort_by{|k, v| v}]
      results = sort_results.first(5)
      return Hash[results]
    end

end
