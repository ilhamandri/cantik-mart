class NotificationsController < ApplicationController
  before_action :require_login
  before_action :require_fingerprint

  def index
    @notifications = Notification.where(to_user: current_user).order("date_created DESC").page param_page
    @notifications = @notifications.where(to_user: current_user)
    if params[:search].present?
      @search = params[:search].downcase
      search = "%"+@search+"%"
      @notifications = @notifications.where("lower(name) like ? OR phone like ?", search, search)
    end
  end

  private
    def param_page
      params[:page]
    end
  
end
