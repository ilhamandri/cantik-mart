class VouchersController < ApplicationController
  before_action :require_login

  def index
  	@vouchers = Voucher.page param_page
  end

  private 
  	def param_page
  		params[:page]
  	end

end