class SendBacksController < ApplicationController
  before_action :require_login

  def index
  	@send_backs = SendBack.page param_page
  end

  def new
  end

  def create
  end

  private
  	def param_page
  		params[:page]
  	end

end