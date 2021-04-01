class CheatsController < ApplicationController
  before_action :require_login
  before_action :require_fingerprint

  def index
    if !["pardev1@pardev.co.id", "kindi@cantikmart.com"].include? current_user.email
  	 return redirect_back_data_error homes_path, "Halaman Tidak Ditemukan"
    end
    @trxs = Transaction.where("invoice like '%/TP'").order("date_created DESC")
  	if params[:date].present?
  		search_date = params[:date].to_datetime
  		@trxs = @trxs.where(created_at: search_date.beginning_of_day..search_date.end_of_day)
  	end
  	if params[:user_id] != "0"
  		@trxs = @trxs.where(user_id: params[:user_id])
  	end

  	if params[:store_id] != "0"
  		@trxs = @trxs.where(store_id: params[:store_id])
  	end

  	@trxs = @trxs.page params_page
  end

  def show
    return redirect_back_data_error transactions_path, "Data Transaksi Tidak Ditemukan" if params[:id].nil?
    @transaction_items = TransactionItem.where(transaction_id: params[:id])
    return redirect_back_data_error transactions_path, "Data Transaksi Tidak Ditemukan" if @transaction_items.empty?
  end


  private
  	def params_page
  		params[:page]
  	end

end