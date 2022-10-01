class LogsController < ApplicationController
  before_action :require_login
  before_action :screening

  def index
    @logs = UserDevice.page param_page
  end

  private
    def param_page
      params[:page]
    end
end