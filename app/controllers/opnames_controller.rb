class OpnamesController < ApplicationController
  before_action :require_login
  before_action :screening

  def index
  	@opnames = Opname.where(store: current_user.store).includes(:store, :user).order("created_at DESC").page param_page
  end

  private 
  	def param_page
  		params[:page]
  	end
end	