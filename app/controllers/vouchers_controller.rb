class VouchersController < ApplicationController
  before_action :require_login
  before_action :screening

  def index
  	@vouchers = Voucher.order("used ASC").page param_page
  end

  private 
  	def param_page
  		params[:page]
  	end

end