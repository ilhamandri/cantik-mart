class CheatsController < ApplicationController
  before_action :require_login
  before_action :require_fingerprint

  def index
  	@trxs = Transaction.where("invoice like '%/TP'")
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


  private
  	def params_page
  		params[:page]
  	end

end