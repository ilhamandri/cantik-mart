class PopularsController < ApplicationController
  before_action :require_login

  def index
    @date = search_date
    item_cats_data = higher_item_cats_graph @date
    gon.higher_item_cats_data = item_cats_data.values
    gon.higher_item_cats_label = item_cats_data.keys

    item_cats_data = lower_item_cats_graph @date
    gon.lower_item_cats_data = item_cats_data.values
    gon.lower_item_cats_label = item_cats_data.keys

    @higher_item = higher_item @date
    @lower_item = lower_item @date
  end

  private
    def param_page
      params[:page]
    end

    def higher_item date
      PopularItem.where(item_cat_id: 134).destroy_all
      item_sells = PopularItem.where(store: current_user.store).where("date = ?", date).order("n_sell DESC").limit(20).pluck(:item_id, :n_sell)
      return Hash[item_sells]
    end

    def lower_item date
      item_sells = PopularItem.where(store: current_user.store).where("date = ?", date).order("n_sell ASC").limit(20).pluck(:item_id, :n_sell)
      return Hash[item_sells]
    end

    def higher_item_cats_graph date
      item_cats = {}
      item_sells = PopularItem.where(store: current_user.store).where("date = ?", date).order("n_sell DESC").limit(100).pluck(:item_id, :n_sell)
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

    def lower_item_cats_graph date
      item_cats = {}
      item_sells = PopularItem.where(store: current_user.store).where("date = ?", date).order("n_sell ASC").limit(100).pluck(:item_id, :n_sell)
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

    def search_date
      month_param = params[:month]
      year_param = params[:year]
      date = nil
      if (year_param.present?) && (month_param.present?)
        date = (month_param.to_s + year_param.to_s).to_datetime.beginning_of_month
      end
      
      return date
      
    end 
end
