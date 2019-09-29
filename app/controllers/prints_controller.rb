class PrintsController < ApplicationController
  before_action :require_login

  def index
  	@prints = Print.where(store: current_user.store)
  end

end