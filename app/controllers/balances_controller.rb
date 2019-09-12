class BalancesController < ApplicationController
  before_action :require_login
  before_action :require_fingerprint

  def index
  	@balances = StoreBalance.page param_page
  	filter_search = search @balances
  	@balances = filter_search[0]
  	@search = filter_search[1]
    @params = params[:balance]
  end

  def show
  	return redirect_back_data_error orders_path, "Data Keuangan Tidak Ditemukan" unless params[:id].present?
    @balance = StoreBalance.find_by(id: params[:id])
    return redirect_back_data_error orders_path, "Data Keuangan Tidak Ditemukan" unless @balance.present?
  end

  def refresh
    AccountBalance.balance_account
  	return redirect_to balances_path
  end

  private
  	def param_page
  		params[:page]
  	end

  	def search balances
  		search_text = ""
  		return [balances, search_text] if params[:balance].nil?

      balances = balances.where(store: current_user.store) if !["owner", "super_admin"].include? current_user.level 

  		switch_date_month = params[:balance][:switch_date_month]
  		date_from = params[:balance][:date_from]
  		date_to = params[:balance][:date_to]
  		month = params[:balance][:month]
  		order_by = params[:balance][:order_by]

  		if switch_date_month.present?
  			if switch_date_month == "month"
  				if month.present?
  					search_text += "Pencarian " + month.to_s + " bulan terakhir"
  					date_from = (DateTime.now - month.to_i.months).beginning_of_day
  					balances = balances.where("created_at >= ?", date_from)
  				end
  			else
  				if date_from.present? && date_to.present?
  					d_date_from = date_from.to_datetime.beginning_of_day
  					d_date_to = date_to.to_datetime.end_of_day
  					search_text += "Pencarian dari "+d_date_from.to_date.to_s + " - " + d_date_to.to_date.to_s
  					balances = balances.where("created_at >= ? AND created_at <= ?", d_date_from, d_date_to)
  				end
  			end	
  		end

  		if order_by.present?
  			if order_by == "desc"
  				balances = balances.order("created_at DESC")
  				search_text += " secara menurun"
  			else
  				search_text += " secara menaik"
  			end
  		end

  		return [balances, search_text]
  	end
 end