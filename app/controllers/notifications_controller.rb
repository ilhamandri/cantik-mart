class NotificationsController < ApplicationController
  before_action :require_login
  before_action :screening
  

  def index
    @notifications = Notification.where(to_user: current_user).includes(:from_user).order("date_created DESC")
    @notifications.update_all(read: 0)
    @notifications = @notifications.page param_page
  end

  private
    def param_page
      params[:page]
    end
  
end
