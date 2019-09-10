class HomesController < ApplicationController
  before_action :require_login
  require 'usagewatch'

  def index
    @total_limit_items = StoreItem.where(store_id: current_user.store.id).where('stock < min_stock').count
    @total_orders = Order.where(store_id: current_user.store.id).where('date_receive is null').count
    @total_payments = Order.where(store_id: current_user.store.id).where('date_receive is not null and date_paid_off is null').count
    @total_returs = Retur.where(store_id: current_user.store.id).where('date_picked is not null').count
  	# UserMailer.welcome_email("kevin.rizkhy85@gmail.com", "Subject 1").deliver
  	

    item_cats_data = higher_item_cats_graph
    gon.higher_item_cats_data = item_cats_data.values
    gon.higher_item_cats_label = item_cats_data.keys

    item_cats_data = lower_item_cats_graph
    gon.lower_item_cats_data = item_cats_data.values
    gon.lower_item_cats_label = item_cats_data.keys

    @higher_item = higher_item
    @lower_item = lower_item

    @debt = Debt.where("deficiency > ?",0)
    @receivable = Receivable.where("deficiency > ?",0)

  end

  private
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
