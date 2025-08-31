class LogsController < ApplicationController
  before_action :require_login
  before_action :screening

  def index
    Thread.start{
      end_date = DateTime.now - 6.months
      UserDevice.where("created_at <= ?", end_date).destroy_all
    }
    @logs = UserDevice.page param_page
  end

  private
    def param_page
      params[:page]
    end
end