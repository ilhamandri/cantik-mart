class SalariesController < ApplicationController
  before_action :require_login
  before_action :require_fingerprint

  def index
  	AccountBalance.salary
  	@salaries = UserSalary.page param_page
  end

  private
  	def param_page
  		params[:page]
  	end
  
end